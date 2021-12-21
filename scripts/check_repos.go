package main

import (
	"bufio"
	"encoding/base64"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

// fileInfo represents file information from the github api. fileInfo does not contain all fields.
type fileInfo struct {
	Name    string `json:"name"`
	Path    string `json:"path"`
	Content string `json:"content"`
	Type    string `json:"type"`
}

// decodeFileInfo decodes the file information from the github api into fileInfo struct.
func decodeFileInfo(r io.Reader, record string) fileInfo {
	var info fileInfo
	err := json.NewDecoder(r).Decode(&info)
	if err != nil {
		log.Fatalf("%s: Unable to decode file info for %s", err, record)
	}
	return info
}

// decodeFileInfos decodes the file information from the github api into fileInfo struct array. Used for folders.
func decodeFileInfos(r io.Reader) []fileInfo {
	var infos []fileInfo
	err := json.NewDecoder(r).Decode(&infos)
	if err != nil {
		panic(err)
	}
	return infos
}

// flattenArray turns a 2D array into a 1D array.
func flattenArrary(arr [][]string) []string {
	var result []string
	for _, v := range arr {
		result = append(result, v...)
	}
	return result
}

func getVisited() []string {
	file, err := os.Open("../visited.txt")
	if err != nil {
		panic(err)
	}

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	return lines
}

func writeVisited(record string) {
	file, err := os.OpenFile("../visited.txt", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0777)
	defer file.Close()
	if err != nil {
		panic(err)
	}
	if _, err := file.WriteString(record + "\n"); err != nil {
		log.Println(err)
	}
}

func filterRecords(records []string, visited []string) []string {
	var toVisit []string
	sort.Strings(visited)
	for _, record := range records {
		if !exists(visited, record) {
			toVisit = append(toVisit, record)
		}
	}
	return toVisit
}

func exists(strings []string, e string) bool {
	i := sort.SearchStrings(strings, e)
	if i < len(strings) && strings[i] == e {
		return true
	}
	return false
}

// readGithubTokens reads the github tokens from a file.
func readGithubTokens() []string {
	f, err := os.Open("../tokens.secret")
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	var lines []string

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if line != "" {
			lines = append(lines, strings.Split(line, " ")[0])
		}
	}
	return lines
}

// TODO: rephrase this go-doc comment to explain why 2D array is the case.
// parseCsv takes a csv file and returns a 2D array of strings.
func parseCsv(filePath string) [][]string {
	f, err := os.Open(filePath)
	if err != nil {
		log.Fatalf("%s: Unable to read input file %s", err, filePath)
	}
	defer f.Close()

	csvReader := csv.NewReader(f)
	records, err := csvReader.ReadAll()
	if err != nil {
		log.Fatalf("%s: Unable to parse file as CSV for %s", err, filePath)
	}

	return records
}

// chunkRecord splits a string array into chunks based on the number of CPU cores.
func chunkRecords(records []string) [][]string {
	var divided [][]string
	numCPU := runtime.NumCPU()
	chunkSize := (len(records) + numCPU - 1) / numCPU

	for i := 0; i < len(records); i += chunkSize {
		end := i + chunkSize
		if end > len(records) {
			end = len(records)
		}
		divided = append(divided, records[i:end])
	}

	return divided
}

// buildRequest builds a request with the given url and Github token and returns the request.
func buildRequest(url, token string) *http.Request {
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("Authorization", fmt.Sprintf("token %s", token))
	return req
}

// getRateLimitRemaining returns the remaining rate limit on the given token.
func getRateLimitRemaining(token string) (int, int64) {
	req := buildRequest("https://api.github.com/rate_limit", token)
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal("Unable to get rate limit", err)
	}
	if resp.StatusCode != 200 {
		log.Fatalf("%d Bad credentials: %s", resp.StatusCode, token)
	}
	remaining, _ := strconv.Atoi(resp.Header.Get("X-RateLimit-Remaining"))
	reset, _ := strconv.Atoi(resp.Header.Get("X-RateLimit-Reset"))
	return remaining, int64(reset)
}

// getFileContent gets the file contents from a given repo and path. Supports both folders and files.
func getRepoContetAt(record, path, token string) *http.Response {
	url := fmt.Sprintf("https://api.github.com/repos/%s/contents/%s", record, path)
	req := buildRequest(url, token)
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal("Unable to get workflow info for "+record, err)
	}
	return resp
}

// transformFileName ...
func transformFileName(filePath string) string {
	transformed := strings.ReplaceAll(filePath, "/", "_")
	return transformed
}

// decodeBase64 takes a base64 encoded string and returns the decoded string.
func decodeBase64(data string) string {
	decoded, err := base64.StdEncoding.DecodeString(data)
	if err != nil {
		log.Println("Unable to decode base64", err)
		return ""
	}
	return string(decoded)
}

// writeToFile writes the content to the file.
func writeToFile(record string, file fileInfo) {
	f, err := os.OpenFile(fmt.Sprintf("../out/%s/%s", record, transformFileName(file.Path)),
		os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0777)
	if err != nil {
		panic(err)
		// log.Println(err)
		// return
	}
	defer f.Close()
	if _, err := f.WriteString(decodeBase64(file.Content)); err != nil {
		log.Println(err)
	}
}

// createdDirectory creates the directory from a given path - absolute or relateive - if it doesn't exist.
func createDirectory(dir string) {
	path := filepath.Join("../out", dir)
	if _, err := os.Stat(path); os.IsNotExist(err) {
		os.MkdirAll(path, 0777)
	}
}

// sleepUntil sleeps until the the given timestamp. Timestamp is in seconds since epoch (Jan 1 1970).
func sleepUntil(timestamp int64) {
	wakeUpAt := time.Unix(timestamp, 0).Add(time.Duration(time.Minute * 2)) // add 2 minutes just to be sure
	log.Printf("Rate limit reached. Sleeping until %s. Good night...", wakeUpAt.Format("2006-01-02 15:04:05"))
	time.Sleep(time.Until(wakeUpAt))
}

func parseFile(record, token string, file fileInfo) {
	res := getRepoContetAt(record, file.Path, token)
	fileInfo := decodeFileInfo(res.Body, record)
	writeToFile(record, fileInfo)
}

func iterateFiles(record, token string, files []fileInfo) {
	for _, file := range files {
		if file.Type == "file" {
			parseFile(record, token, file)
		} else if file.Type == "dir" {
			folder := getRepoContetAt(record, file.Path, token)
			folderDecoded := decodeFileInfos(folder.Body)
			iterateFiles(record, token, folderDecoded)
		}
	}
}

// crawl crawls the github repos and writes the files to the output directory.
func crawl(records []string, token string) {
	for index, record := range records {
		// check before each run if there is enough quota to make requests
		remaining, reset := getRateLimitRemaining(token)
		if remaining < 20 {
			sleepUntil(reset)
		}

		res := getRepoContetAt(record, ".github/workflows", token)
		if res.StatusCode == 200 {
			createDirectory(record)
			files := decodeFileInfos(res.Body)
			iterateFiles(record, token, files)
		}
		log.Printf("%s\n%s\nLeft in chunk: %d\n\n", record, res.Status, len(records)-index)
		writeVisited(record)
	}
}

// program starts here.
func main() {
	tokens := readGithubTokens()
	records := parseCsv("../repos.csv")
	visitedRepos := getVisited()
	recordsFlat := flattenArrary(records)
	recordsToVisit := filterRecords(recordsFlat, visitedRepos)
	chunks := chunkRecords(recordsToVisit)

	var wg sync.WaitGroup
	wg.Add(len(chunks))

	for i, records := range chunks {
		go func(rcds []string, token string, index int) {
			crawl(rcds, token)
			log.Printf("Finished crawling chunk %d\n", index)
			defer wg.Done()
		}(records, tokens[i%len(tokens)], i)
	}
	wg.Wait()
}
