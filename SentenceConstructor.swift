import Foundation

extension String {
  subscript (i: Int) -> Character {
    return self[advance(self.startIndex, i)]
  }

  subscript (i: Int) -> String {
    return String(self[i] as Character)
  }

  subscript (r: Range<Int>) -> String {
    return substringWithRange(Range(start: advance(startIndex, r.startIndex), end: advance(startIndex, r.endIndex)))
  }
}

public class BotHelper {
    class func maxSentenceLength() -> Int {
        return 20
    }

    class func markovChainOrder() -> Int {
        return 2
    }

    class func stopSymbols() -> Array<String> {
        return [".", "\"", ";", "!", "?"]
    }

    class func stopWords() -> Array<String> {
        let fileContent = String(contentsOfFile: "stop_words.txt", 
                                       encoding: NSUTF8StringEncoding, 
                                          error: nil)
        return fileContent!.componentsSeparatedByCharactersInSet(
                NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }

    class func randomChoice<T>(arr : Array<T>) -> T {
        let randomIndex = Int(arc4random_uniform(UInt32(arr.count)))
        return arr[randomIndex]
    }

    class func HarryPotterBot() -> SentenceConstructorBot {
        let files = ["hp1.txt", "hp2.txt", "hp3.txt", "hp4.txt", "hp5.txt", "hp6.txt", "hp7.txt"] 
        return SentenceConstructorBot(corpusFileNames : files, 
                              maxSentenceLength : self.maxSentenceLength(),
                              order : self.markovChainOrder())
    }

    class func TolkienBot() -> SentenceConstructorBot {
        let files = ["silmarillion.txt", "fellowship.txt", "two_towers.txt", "return.txt", "hobbit.txt"]
        return SentenceConstructorBot(corpusFileNames : files, 
                              maxSentenceLength : self.maxSentenceLength(),
                              order : self.markovChainOrder())
    }

    class func DanBrownBot() -> SentenceConstructorBot {
        let files = ["deception_point.txt", "digital_fortress.txt", "angels_demons.txt", "davinci_code.txt"]
        return SentenceConstructorBot(corpusFileNames : files, 
                              maxSentenceLength : self.maxSentenceLength(),
                              order : self.markovChainOrder())
    }

    class func DanteBot() -> SentenceConstructorBot {
        let files = ["divine_comedy.txt"]
        return SentenceConstructorBot(corpusFileNames : files, 
                              maxSentenceLength : self.maxSentenceLength(),
                              order : self.markovChainOrder())
    }
    
    class func JaneAustenBot() -> SentenceConstructorBot {
        let files = ["pride.txt", "sense.txt", "persuasion.txt", "emma.txt"]
        return SentenceConstructorBot(corpusFileNames : files, 
                              maxSentenceLength : self.maxSentenceLength(),
                              order : self.markovChainOrder())
    }
    
    class func HodgePodgeBot() -> SentenceConstructorBot {
        let files = ["pride.txt", "hp7.txt", "divine_comedy.txt", "davinci_code.txt", "fellowship.txt"]
        return SentenceConstructorBot(corpusFileNames : files, 
                              maxSentenceLength : self.maxSentenceLength(),
                              order : self.markovChainOrder())
    }
    
    class func MathBot() -> SentenceConstructorBot {
        let files = ["math_phil.txt", "logic.txt", "algebra.txt", "geometry.txt"]
        return SentenceConstructorBot(corpusFileNames : files, 
                              maxSentenceLength : self.maxSentenceLength(),
                              order : self.markovChainOrder())
    }
}
        
public class SentenceConstructorBot {
    private var corpusFileNames : Array<String>
    private var maxSentenceLength : Int
    private var forwardTransitionsMap : Dictionary<String, Array<String>>
    private var backwardTransitionsMap : Dictionary<String, Array<String>>
    private var order : Int

    init(corpusFileNames : Array<String>, 
       maxSentenceLength : Int, 
       order : Int) {
        self.corpusFileNames = corpusFileNames
        self.maxSentenceLength = maxSentenceLength
        self.forwardTransitionsMap = [String : Array<String>]()
        self.backwardTransitionsMap = [String : Array<String>]()
        self.order = order
        train()
    }

    private func train() {
        for location in self.corpusFileNames {
            let fileContent = String(contentsOfFile: "texts/" + location, 
                                           encoding: NSUTF8StringEncoding, 
                                              error: nil)
            if fileContent == nil {
                println("Cannot open \(location)")
                continue
            }
            
            func nonZeroLen(str : String) -> Bool {
                return count(str) > 0
             }
            
            let words : Array<String> = fileContent!.componentsSeparatedByCharactersInSet(
                NSCharacterSet.whitespaceAndNewlineCharacterSet()).filter(nonZeroLen)
            let reverseWords : Array<String> = words.reverse()
            self.forwardTransitionsMap = self.addTransitionsForWords(words, transitionsMap:self.forwardTransitionsMap)
            self.backwardTransitionsMap = self.addTransitionsForWords(reverseWords, transitionsMap:self.backwardTransitionsMap)
       }
    }
    
    private func addTransitionsForWords(words : Array<String>,
        var transitionsMap : Dictionary<String, Array<String>>) 
         -> Dictionary<String, Array<String>>{ 
        let numWords = words.count
        for index in 0...numWords - self.order - 1 {
            let currentBuffer : Array<String> = Array(words[index..<index + self.order])
            let transitionFrom = join(" ", currentBuffer)
            let transitionTo = words[index + order]

            if transitionsMap[transitionFrom] == nil {
                var valueList = Array<String>()
                transitionsMap[transitionFrom] = valueList
            }

            transitionsMap[transitionFrom]!.append(transitionTo)
        }

        return transitionsMap
    }

    public func generateResponseForSentence(sentence : String) -> String {
        let words : Array<String> = sentence.componentsSeparatedByString(" ")
        func filterWord(word : String) -> Bool {
            return contains(BotHelper.stopWords(), word) 
        }

        let randomWord : String = BotHelper.randomChoice(words)
        let keys : Array<String> = self.backwardTransitionsMap.keys.array

        func filterKey(key : String) -> Bool {
            return key.rangeOfString(randomWord) != nil
        }

        let eligibleKeys : Array<String> = keys.filter(filterKey)
        if eligibleKeys.count == 0 {
            return self.generateSentence()
        }

        let randomKey = BotHelper.randomChoice(eligibleKeys)
        let keyWords = randomKey.componentsSeparatedByString(" ")
        let sentenceBeginning = join(" ", 
                self.generateSentenceWithInitialKey(randomKey, forward:false).componentsSeparatedByString(" ").reverse())
        
        let reversedKey = join(" ", keyWords.reverse())
        let sentenceEnd = self.generateSentenceWithInitialKey(reversedKey)
        if sentenceEnd ==  "Sorry, we cannot generate a sentence with that initial key" {
            return sentenceBeginning + " " + self.generateSentence()
        } else {
            let endWords = sentenceEnd.componentsSeparatedByString(" ")
            return sentenceBeginning + join(" ", endWords[3..<endWords.count])
        }
    }

    public func generateSentenceWithInitialKey(initialKey : String,
        forward : Bool = true,
        initialSentenceLength : Int = 0) -> String {  
        let transitionsMap : Dictionary<String, Array<String>> =
            forward ? self.forwardTransitionsMap : self.backwardTransitionsMap
        let keys : Array<String> = transitionsMap.keys.array
        var sentence : String = ""
        var currentSentenceLength : Int = self.order + initialSentenceLength 
        
        let keyComponents = initialKey.componentsSeparatedByString(" ")
        let keyWordCount = keyComponents.count
        if keyWordCount < self.order {
            return "Please give me a longer key"
        } else if keyWordCount > self.order {
            currentSentenceLength += keyWordCount - self.order
            sentence += " " + join(" ", Array(keyComponents[0..<keyComponents.count - self.order]))
        }
        
        var currentKey : String = join(" ", Array(keyComponents[keyComponents.count - self.order..<keyComponents.count]))

        if transitionsMap[currentKey] == nil {
            return "Sorry, we cannot generate a sentence with that initial key"
        }

        sentence += " " + currentKey

        while true {
            let currentValue : String = BotHelper.randomChoice(transitionsMap[currentKey]!)
            sentence += " " + currentValue
            
            let stopCondition : Bool = forward ? contains(BotHelper.stopSymbols(), currentValue[count(currentValue) - 1])
                : currentValue.capitalizedString[0] as String == currentValue[0] as String
            if count(currentValue) < 1 ||  stopCondition {
                if currentSentenceLength >= maxSentenceLength || stopCondition {
                    break
                } else {
                    currentKey = BotHelper.randomChoice(keys)
                    sentence += " " + currentKey
                    currentSentenceLength += 2
                    continue
                }
            } 

            let concat : String = currentKey + " " + currentValue
            let components : Array<String> = concat.componentsSeparatedByString(" ")
            currentKey = join(" ", Array(components[1..<components.count]))
            currentSentenceLength = sentence.componentsSeparatedByString(" ").count
        }
        return sentence
    }

    public func generateSentence() -> String { 
        let keys : Array<String>= self.forwardTransitionsMap.keys.array
        let key : String = BotHelper.randomChoice(keys)
        return self.generateSentenceWithInitialKey(key)
    }
}

func main() {
    let titleFileContent = String(contentsOfFile: "title.txt", 
                                        encoding: NSUTF8StringEncoding, 
                                           error: nil)
    if titleFileContent != nil {
        println(titleFileContent! + "\n\n\n  Ready!\n\n")
    }

    var botCache = [NSString : SentenceConstructorBot]()
    waitingOnInput: while true {
        println("Enter command below:")
        var fh : NSFileHandle  = NSFileHandle.fileHandleWithStandardInput()
        let data : NSData = fh.availableData
        var str : NSString? = NSString(data: data, encoding: NSUTF8StringEncoding)
        botCache = parseCommand(botCache, str!) 
    }
}

func parseCommand(var botCache : Dictionary<NSString, SentenceConstructorBot>, 
        userInput : NSString) -> Dictionary<NSString, SentenceConstructorBot> {
    println()
    let args = userInput.stringByTrimmingCharactersInSet(
            NSCharacterSet.newlineCharacterSet()).componentsSeparatedByString(" ")
    let botName : String = args[0]
    let voice : String = args[2]
    var initialKey : String = ""
    let shouldGenerateResponse = args.count > 3 && args[3] == "-c"
    let argLimit = shouldGenerateResponse ? 5 : 4

    if args.count >= argLimit {
        initialKey = join(" ", Array(args[argLimit - 1..<args.count]))
    }

    if botCache[botName] == nil {
        println("    Training \(botName)...")
        var bot = botForString(botName)
        botCache[botName] = bot
    } else {
        println("    Trained model for \(botName) found!")
    }

    println()
    println("    Generating Sentence for \(botName) ...")
    var output : String
    if shouldGenerateResponse && count(initialKey) > 0 {
        output = botCache[botName]!.generateResponseForSentence(initialKey) 
    } else if count(initialKey) > 0 {
        output = botCache[botName]!.generateSentenceWithInitialKey(initialKey)
    } else {
        output = botCache[botName]!.generateSentence()
    }

    println("    $> " + output)
    shell("say", "-v", voice, output)
    println()

    return botCache
}

func botForString(str : NSString) -> SentenceConstructorBot {
    switch str {
        case "HarryPotter":
            return BotHelper.HarryPotterBot()
        case "Tolkien":
            return BotHelper.TolkienBot()
        case "DanBrown":
            return BotHelper.DanBrownBot()
        case "Dante":
            return BotHelper.DanteBot()
        case "JaneAusten":
            return BotHelper.JaneAustenBot()
        case "HodgePodge":
            return BotHelper.HodgePodgeBot()
        case "Math":
            return BotHelper.MathBot()
        default:
            return BotHelper.DanteBot()
    }
}

func shell(args: String...) {
    let task = NSTask()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
}

main()
