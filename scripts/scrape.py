import requests
import json
from bs4 import BeautifulSoup

def do_work(name):
    try:
        tmp = name.split('/')[:2]
        url_name = "/".join(tmp)
        gh_path = f"https://github.com/{url_name}"

        r = requests.get(gh_path)
        if r.status_code != 200:
            raise Exception(f"{url_name} repo not found, status_code: {r.status_code}")

        b = BeautifulSoup(r.text, 'html.parser')
        path = b.select(
            '#repo-content-pjax-container > div > div.Layout.Layout--flowRow-until-md.Layout--sidebarPosition-end.Layout--sidebarPosition-flowRow-end > div.Layout-main > div.flex-justify-between.flex-items-center.flash.mb-3.d-flex > a')[0]['href']

        r = requests.get('https://github.com' + path)
        if r.status_code != 200:
            raise Exception(f"{url_name} is not a valid github user")

        b = BeautifulSoup(r.text, 'html.parser')
        category = b.select(
            '#js-pjax-container > div > div > div:nth-child(3) > aside > div:nth-child(3) > div > a')

        categories = []
        for cat in category:
            if cat:
                trimmed = cat.get_text().strip()
                if(trimmed != ""):
                    categories.append(trimmed)
        return categories
    except Exception as e:
        print("det fejlede kammarat!", e)
        # write to file that the scraping failed
        f = open('scrapes_that_failed_temp.txt', 'a')
        f.write(f'{url_name} - {name} - {e} \n')


def main(filePath: str):
    data = open(filePath, 'r')
    result = {}
    i = 0
    for action in data:
        i += 1
        action = action.strip()
        print (f"progress {i}/1784, checking {action}")
        categories = do_work(action)
        if categories and action not in result.keys():
            result[action] = categories

    print(result)
    with open("categories", "w") as outfile:
        json.dump(result, outfile)

if __name__ == '__main__':
    main('actions_out/unique_actions_list.txt')