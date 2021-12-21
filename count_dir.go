package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	folders, _ := os.ReadDir("./out")

	count := 0
	for _, f := range folders {
		subfolders, _ := os.ReadDir("./out/" + f.Name())
		count += len(subfolders)
	}
	fmt.Println(count)

	// iterate("./out")
}

func readFileIntoString(path string) string {
	file, err := os.Open(path)

	if err != nil {
		log.Fatalf(err.Error())
	}
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		log.Fatalf(err.Error())
	}

	return strings.Join(lines, "\n")
}

func iterate(path string) {
	count := 0
	numberOfFiles := 0
	filepath.Walk(path, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			log.Fatalf(err.Error())
		}
		if strings.HasSuffix(info.Name(), ".yml") || strings.HasSuffix(info.Name(), ".yaml") {
			file := readFileIntoString(path)
			count += strings.Count(file, "uses:")
			numberOfFiles++
		}
		return nil
	})
	fmt.Println(count)
	fmt.Println(numberOfFiles)

}
