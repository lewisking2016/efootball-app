import urllib.request
import os

os.makedirs("assets/logos", exist_ok=True)
os.makedirs("assets/tournaments", exist_ok=True)

teams = {
    # 20 EPL Teams
    "arsenal": 9825, "astonvilla": 10252, "bournemouth": 8678, "brentford": 10172,
    "brighton": 8644, "chelsea": 8455, "crystalpalace": 9826, "everton": 8668,
    "fulham": 8702, "ipswich": 8027, "leicester": 8197, "liverpool": 8650,
    "mancity": 8456, "manutd": 8654, "newcastle": 8611, "nottmforest": 10203,
    "southampton": 8466, "tottenham": 8251, "westham": 8659, "wolves": 8602,
    # Requested additions (EFL Championship / Popular)
    "sunderland": 8472, "leeds": 8463, "sheffieldutd": 8651, "burnley": 8191, "westbrom": 8652
}

for name, tid in teams.items():
    url = f"https://images.fotmob.com/image_resources/logo/teamlogo/{tid}.png"
    print(f"Downloading {name}...")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            with open(f"assets/logos/{name}.png", 'wb') as f:
                f.write(response.read())
    except Exception as e:
        print(f"Failed {name}: {e}")

tournaments = {
    "epl": 47,
    "la_liga": 87,
    "serie_a": 55,
    "champions_league": 42,
    "fa_cup": 132
}

for name, tid in tournaments.items():
    url = f"https://images.fotmob.com/image_resources/logo/leaguelogo/{tid}.png"
    print(f"Downloading {name} Trophy...")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0'})
        with urllib.request.urlopen(req) as response:
            with open(f"assets/tournaments/{name}.png", 'wb') as f:
                f.write(response.read())
    except Exception as e:
        print(f"Failed {name}: {e}")

print("All Tournaments Done!")
