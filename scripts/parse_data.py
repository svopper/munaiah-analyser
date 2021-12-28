import sys
import json
import os.path

def read_json(file_path: str) -> dict:
  if os.path.exists(file_path):
    f = open(file_path, 'r')
    json_dict = json.load(f)
    f.close()
    return json_dict
  else:
    return None

def get_repodata(path: str) -> dict:
  dir_path = path.split('/')[:-1]
  dir_path = '/'.join(dir_path)
  file_path = f"{dir_path}/repodata.json"
  temp = read_json(file_path)
  repo_data = dict()
  if temp is None:
    repo_data['language'] = ''
    return repo_data
  else:
    repo_data['language'] = temp['language']
    return repo_data

def get_actions(path: str) -> list[str]:
  workflow_file = path.split(' ')[0]
  file_path = f"{workflow_file}.action_count.txt"
  actions = open(file_path).readlines()
  if actions is None:
    return []

  return actions

def get_short_name(action: str) -> str:
  action = action.split('@')
  return action[0]

def get_name(path: str) -> str:
  author_repo = path.split('/')[2:4]
  return '/'.join(author_repo)

def parse_to_csv(paths: list[str]) -> list[str]:
  rows = []
  for path in paths:
    name = get_name(path)
    actions = get_actions(path)
    repo_data = get_repodata(path)
    for action in actions:
      short_name = get_short_name(action)
      row = f"{name},{action.strip()},{short_name},{repo_data['language']}"
      rows.append(row)
  return rows

def read_input() -> list[str]:
  return [line.strip() for line in sys.stdin]

def main():
  # reads paths to workflow files from stdin
  # in the following format: /path/to/workflow/file/
  paths = read_input()
  rows = parse_to_csv(paths)
  print('repo_name,action_name,action_short_name,language')
  print('\n'.join(rows))

if __name__ == '__main__':
  main()