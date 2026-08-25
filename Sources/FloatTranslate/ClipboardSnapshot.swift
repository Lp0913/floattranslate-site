import AppKit

struct ClipboardSnapshot {
    struct Item {
        let representations: [NSPasteboard.PasteboardType: Data]
    }

    let items: [Item]

    init(items: [Item]) {
        self.items = items
    }

    init(pasteboard: NSPasteboard) {
        items = (pasteboard.pasteboardItems ?? []).map { pasteboardItem in
            let representations = Dictionary(
                uniqueKeysWithValues: pasteboardItem.types.compactMap { type in
                    pasteboardItem.data(forType: type).map { (type, $0) }
                }
            )
            return Item(representations: representations)
        }
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        let pasteboardItems = makePasteboardItems()
        if !pasteboardItems.isEmpty {
            pasteboard.writeObjects(pasteboardItems)
        }
    }

    func makePasteboardItems() -> [NSPasteboardItem] {
        items.map { item in
            let pasteboardItem = NSPasteboardItem()
            for (type, data) in item.representations {
                pasteboardItem.setData(data, forType: type)
            }
            return pasteboardItem
        }
    }
}
