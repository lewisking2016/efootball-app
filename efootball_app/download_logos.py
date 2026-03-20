import urllib.request
import os

logos = {
    'efootball.png': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/EFootball_logo.svg/512px-EFootball_logo.svg.png',
    'epl_lion.png': 'https://upload.wikimedia.org/wikipedia/en/thumb/f/f2/Premier_League_Logo.svg/512px-Premier_League_Logo.svg.png',
    'arsenal.png': 'https://upload.wikimedia.org/wikipedia/en/thumb/5/53/Arsenal_FC.svg/512px-Arsenal_FC.svg.png',
    'mancity.png': 'https://upload.wikimedia.org/wikipedia/en/thumb/e/eb/Manchester_City_FC_badge.svg/512px-Manchester_City_FC_badge.svg.png',
    'manutd.png': 'https://upload.wikimedia.org/wikipedia/en/thumb/7/7a/Manchester_United_FC_crest.svg/512px-Manchester_United_FC_crest.svg.png',
    'astonvilla.png': 'https://upload.wikimedia.org/wikipedia/en/thumb/9/9f/Aston_Villa_logo.svg/512px-Aston_Villa_logo.svg.png',
    'liverpool.png': 'https://upload.wikimedia.org/wikipedia/en/thumb/0/0c/Liverpool_FC.svg/512px-Liverpool_FC.svg.png',
}

os.makedirs('assets/logos', exist_ok=True)

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}

for name, url in logos.items():
    try:
        print(f"Downloading {name}...")
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as response:
            with open(f"assets/logos/{name}", 'wb') as f:
                f.write(response.read())
    except Exception as e:
        print(f"Failed to download {name}: {e}")

print("Done downloading logos.")
