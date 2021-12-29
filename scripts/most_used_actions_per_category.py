import json
 
f = open('../data/filtered/cat_joaki.json')
data = json.load(f)

d = {}
set = {}

for k, v in data.items():
    for item in v:
        # Create empty dict if category is not in dictionary
        if d.get(item) is None:
            d[item] = {}

        # Append current action to current category
        d[item][k] = 1


actions = open("../data/actions_out/no_version_actions.txt", "r")

for action in actions:
    # Get action, strip newline and split at @
    action = action.strip()
    b = False

    for c, a in d.items():
        if action in d[c]:
            # Update dictionary if action is in current category
            d[c][action] = d[c][action] + 1
            b = True
    
    set[action] = b

# Find actions that are not present in cat_joaki.json
missing = []
for key, b in set.items():
    if b == False:
        missing.append(key)

# print(sorted(d["Chat"].items(), key=lambda x: x[1], reverse=True))

# Output most used actions in a file for each


for kk in d:
    i = 0
    print("\n")
    print(kk)
    for vv in sorted(d[kk].items(), key=lambda x: x[1], reverse=True):
        if i <= 5:
            print(vv[0] + "," + str(vv[1]))
            i+= 1
        else:
            continue

# print(sorted(d["Chat"].items(), key=lambda x: x[1], reverse=True))

actions.close()
f.close()

