import json
 
f = open('../data/filtered/cat_result_fullname_test.json')
data = json.load(f)

d = {}

# Create dictionary with categories containing an empty list
for k, v in data.items():
    for item in v:

        # Create empty dict if category is not in dictionary
        if d.get(item) is None:
            d[item] = {}

        # Append current action to current category
        d[item][k] = 1


actions = ["actions/create-release", "actions/setup-ruby", "peter-evans/dockerhub-description", "divvun/actions/codesign", "getsentry/action-release"]

for action in actions:
    for c, a in d.items():
        if action in d[c]:
            # Update dictionary if action is in current category
            d[c][action] = d[c][action] + 1

print(d)
f.close()

