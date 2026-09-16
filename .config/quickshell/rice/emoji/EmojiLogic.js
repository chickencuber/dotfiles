
function filterEmojis(items, query) {
    query = query.toLowerCase().trim();

    if (query === "")
        return items;

    return items.filter(item =>
        item.searchString.includes(query)
    ).slice(0, 50);
}

function parseEmojiJson(text) {
    const data = JSON.parse(text);
    const result = [];

    for (const emoji in data) {
        const tags = data[emoji] || [];
        const display = tags.length > 0
            ? tags[0].replace(/_/g, " ")
            : "emoji";

        result.push({
            emoji: emoji,
            display: display,
            searchString: (
                display + " " + tags.join(" ")
            ).toLowerCase()
        });
    }

    return result;
}

function updateRecents(emoji, items, recents) {
    const item = items.find(x => x.emoji === emoji);

    if (!item)
        return recents;

    return [
        item,
        ...recents.filter(x => x.emoji !== emoji)
    ].slice(0, 100);
}
