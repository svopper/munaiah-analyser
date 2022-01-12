# Munaiah Analyser

This project is hosting the code for a research project done at the IT University of Copenhagen in fall 2021.

## Code files

| File                       | Description                                                                                                                                 |
|----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| check_repos.go             | Scrape repos from repos.csv for files in .github/workflows and write to out/                                                                |
| scrape.py (scrape_vlad.py) | Runs through list of unique actions and writes their category to cat_result.json                                                            |
| count_dir.go               | Counts all the y(a)ml files in the /out directory and prints the result to stdout                                                           |
| filter_csv.py              | Takes the CSV dataset downloaded from RepoReapers and writes all rows that has randomforest == 1 to out.csv                                 |
| analysis.py                | TBD                                                                                                                                         |
| sh/get_actions.sh          | (?) Prints actions found in /out to stdout (or file ../actions_out/actions_raw.txt)                                                         |
| sh/get_actions_count.sh    | (?) Takes actions_raw.txt and orders actions by number of uses and writes result to ../actions_out/actions_raw.txt                          |
| sh/get_actions_by_file.sh  | (?) Iterates ../out and counts how many actions each y(a)ml file contains and writes the result to ../actions_out/actions_count_by_file.txt |

## Generated files

| File                                  | Description                                                                                    | Generate by            |
|---------------------------------------|------------------------------------------------------------------------------------------------|------------------------|
| actions_out/actions_count_by_file.txt | Number of action in each y(a)ml file                                                           | get_actions_by_file.sh |
| actions_out/actions_count.txt         | Number of times each action is present across all y(a)ml files                                 | get_actions_count.sh   |
| actions_out/actions_raw.txt           | List of all actions across all files - including dups                                          | ?                      |
| actions_out/no_version_actions.txt    | List of all actions across all files without version specifier - including dups                | analysys.py            |
| actions_out/unique_actions_list.txt   | List of all unique actions                                                                     | analysys.py            |
| manuel/data.md                        | ?                                                                                              | ?                      |
| 429s.txt                              | List of all repos that returned HTTP 429 on scrape                                             | ?                      |
| cat_result.json                       | JSON object with all actions and their categories                                              | scrape.py              |
| repos.csv                             | List of all github repos that use actions and has been identified as SE project by randomfores | ?                      |
| scrapes_that_failed.txt               | List of all failed scrapes including error from scrape.py                                      | scrape.py              |
| table.csv                             | CSV of actions wihtout version and their usage count                                           | analysis.py            |
| visited.txt                           | Includes names of repos that check_repos.go has visited to know where to pick up from          | check_repos.go         |
