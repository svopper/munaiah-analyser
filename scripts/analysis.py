import pandas as pd
from subprocess import call

# Generate raw data file
# call("./get_actions.sh") // Add this if you dont have the out raw data TODO: Replace this with the go script
# Do we add a count for each category a action has or ???

all_actions = open("data/actions_out/actions_raw.txt", "r")
no_ver_actions = open("data/actions_out/no_version_actions.txt", "w")

for i in all_actions:
    tmp = i.split("@")
    no_ver_actions.write(tmp[0] + "\n")

all_actions.close()
no_ver_actions.close()

# Data analysis
data = pd.read_csv(r'data/actions_out/no_version_actions.txt',
                   names=['action_name', 'usages'])
# print(data)

# Write value counts to csv
table = data['action_name'].value_counts()
table.to_csv('table.csv', index=True, header=False)

# Get unique actions names
unique_actions = set(data['action_name'].to_list())

out = open("data/actions_out/unique_actions_list.txt", "w")

for action in unique_actions:
    out.write(action + "\n")

out.close()
