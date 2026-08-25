import AppKit

/// The menu bar status item icon: a speech bubble with two opposing arrows.
/// Embedded as a base64 PNG (the `swiftc` fallback build does not bundle
/// resources) and rendered as a template image. The bubble body is opaque while
/// the background and arrows are transparent cutouts, so macOS tints it to match
/// the menu bar: a light bubble with dark arrows on dark menu bars, and the
/// inverse on light menu bars.
enum StatusBarIcon {
    static func makeImage() -> NSImage? {
        guard let data = Data(base64Encoded: base64PNG),
              let image = NSImage(data: data) else {
            return nil
        }
        image.isTemplate = true
        image.size = NSSize(width: 17, height: 16)
        return image
    }

    private static let base64PNG =
        "iVBORw0KGgoAAAANSUhEUgAAACwAAAAqCAYAAADI3bkcAAAD1klEQVR42s2Zy4sVRxTGf/f29YVvEaMigoiKyizG1aALzSDoRo2CIdkExb2QKPgn+NyoxG2WgSiJzIwI4jPEQBY+wOAimkWMOppIHMyMTu7c6c7mKzg2/ajbd7rHA8X0dHdVf3Xqq++cOrdGsgXAuK67gd3AFmAVMB+YxsTYKDAEPAJuAheBuwkYUq2mBtAD/KBBo4raqED3JOBJBOv+Ho8N1NJswxJAhhq7Fbt/NIYp0bPTgX51SBqkiuacEwF9wvSep2viSx0Y0IvNSQAabw7DgLAFDnQg4McqBBt60qtp6GGxskEPxkriaRxsZGiX9+6Yrrsth/sNf6oAOwj87fnNluEzAF1yfdmedSpzH1gAfAT8bFY2b6L/AesawF5gigYMcnTaLWERc+P/Cfyje9uBy8BGebKR0jcEpgKfAvzUBp8mytungRkCM8dgaGWsTgTcqgEvgUW6kRZV3LPbwO+6LurpSGBPAXfkiNny9Cb9X0/5/iAeMuZmfZ1yzIGbBzzNkby3dfHXx0ZKAhwJ9JByiazVm+a7tG5JvgUe6wOdbL5ZwPdSiYZW8RtgXwol7OablLD7I7DQqMJZT00ep0BiMibeN3Xt20bV55cYDc94anEhwPE8IGxzspHUwNnJNvOX8XblyUpflgzm9f9OdNjjGbAKcdiJ92tFqC7gV8+gkzdmO++3NfCIxN3Z15p101DFpzUT+kwY4NCA7TVge4HhktLOwhx2z94CO4Ab4t56HVDnata1gprsvr/Ql8N5gN0BcTdwSXI0pqN+oJ3fSRBxfdcAF4AlaYdOE3QYyVmi53q50YEnfeyChx6/aShbW5EgUzWBXgwc0dHfeXgJsFxUCTr0cAisBbZqnCBDDv9CMT30yEW/Mp5eDjyo+OgfAucB9udoop3MITPrpcBDw/OJOD7lyeoXaAO9yNFDe3o9bECfq6A04HANAvMCJSUzgY81k3pGzS0Etik9XAscVGGwXuKGdKH7BHDFEX828GQSzna+EfYPYazbasoW89K4Z5oZlgzWcXtzvPLjLvYlpIPRJBUEI7vRkuTOZf+fmxyhZSSlinpby4AdBj6LYSMNdBdwLYUGtvnWxvJafDWvCkMmWBJc/4lyiH8ryHXf6Fu7UrBkJhl1MxDAMlUPV6voMkPPtgLrEk66ruw0pEg6nJEFvgJ+A+4BzxJktC0LMo7cADtjCYuNireBlQVyi8zjUsNDtDGBoRb7hacWS5TcB88BXyoCTvFIjiznSzHnhV2mFBoB74ADZhJ1PhBzgPcY7zxQJb+K3LlwAW+9NlafkigvGerE/gfurzGcgAtBgQAAAABJRU5ErkJggg=="
}
