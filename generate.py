import requests
import re


def stringify_hyphenated_codepoints(hyphenated: str) -> str:
    """attach zero width joiners"""
    return "".join([chr(int(char, 16)) for char in hyphenated.split("-")])


def process_github_emoji_url(emoji_url: str) -> str | None:
    # some of the custom ones have weird urls...
    try:
        normalized = emoji_url.split("/")[-1].split(".png")[0]
        return stringify_hyphenated_codepoints(normalized)
    except:
        return None


def process_unicode_flag_line(line: str) -> str:
    return "".join(chr(int(point, 16)) for point in line.split(";")[0].strip().split())


discord_emojis_api = requests.get(
    "https://emzi0767.mzgit.io/discord-emoji/discordEmojiMap-canary.min.json"
).json()
discord_emojis = {
    emoji["surrogates"]: emoji["primaryNameWithColons"]
    for emoji in discord_emojis_api["emojiDefinitions"]
}

github_emojis_api = requests.get("https://api.github.com/emojis").json()
github_emojis = {
    process_github_emoji_url(emoji_url): f":{emoji_name}:"
    for emoji_name, emoji_url in github_emojis_api.items()
    if process_github_emoji_url(emoji_url)
}

joypixels_emojis_api = requests.get(
    "https://raw.githubusercontent.com/joypixels/emoji-toolkit/refs/heads/master/extras/alpha-codes/eac.json"
).json()
joypixels_emojis = {
    stringify_hyphenated_codepoints(emoji_id): other_info["alpha_code"]
    for emoji_id, other_info in joypixels_emojis_api.items()
}

unicode_emoji_sequences = requests.get(
    "https://unicode.org/Public/emoji/latest/emoji-sequences.txt"
).text
flag_emoji_list = [
    process_unicode_flag_line(line)
    for line in unicode_emoji_sequences.splitlines()
    if "flag:" in line
]
flag_emojis = dict()
for emoji_string, code in github_emojis.items():
    if emoji_string in flag_emoji_list:
        if len(code) > 4:
            flag_emojis[emoji_string] = code
        else:
            flag_emojis[emoji_string] = (
                ":"
                + re.sub(
                    "[^a-z]+",
                    "_",
                    joypixels_emojis_api[
                        "-".join(
                            hex(ord(emoji_char))[2:] for emoji_char in emoji_string
                        )
                    ]["name"][len("flag: ") :].lower(),
                )
                + ":"
            )

emojis_combined = joypixels_emojis | github_emojis | discord_emojis | flag_emojis
print(
    f"#s(hash-table size {len(emojis_combined)} test equal data ({' '.join(f'"{shortcode}" "{emoji}"' for emoji, shortcode in emojis_combined.items())}))"
)
