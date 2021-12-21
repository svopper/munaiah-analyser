def read_failed(filename: str) -> list[str]:
  with open(filename, 'r') as f:
    failed = f.read().splitlines()
  return failed

def filter_failed(failed: list[str]) -> dict:
  local, docker, not_linked, not_valid_user = [], [], [], []

  for line in failed:
    action = line.split(' - ')[0]
    action_full = line.split(' - ')[1]
    error = line.split(' - ')[2]
    if action.startswith('./'):
      local.append(action_full)
    elif action.startswith('docker'):
      docker.append(action_full)
    elif 'is not a valid github user' in error:
      not_valid_user.append(action_full)
    else:
      not_linked.append(action_full)
  
  return dict(local=local, docker=docker, not_valid_user=not_valid_user, not_linked=not_linked)

def main() -> dict:
  failed = read_failed('filtered/scrapes_that_failed_fullname.txt')
  filtered = filter_failed(failed)
  print(filtered)

if __name__ == '__main__':
  main()