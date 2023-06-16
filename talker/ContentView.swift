//
//  ContentView.swift
//  talker
//
//  Created by Alexey Kerpel on 14.06.2023.
//

import OpenAISwift
import SwiftUI
import AVFoundation


struct ContentView: View {
    @StateObject var speechRecognizer = SpeechRecognizer()
    @ObservedObject var gptModel = GPTModel()
    @State private var isRecording = false
    @State var models = [String]()
    @State var req = ""
    
    @State var synthesizer = AVSpeechSynthesizer()
    
    
    final class GPTModel: ObservableObject {
        init() {}
//        private var client: OpenAISwift?
        
        func setup() {
        }
        
        func send(text: String, completion: @escaping (String) -> Void) {
            print("+++")
            print(text)
            print("+++")
            let client = OpenAISwift(authToken: "")
            do {
            client.sendCompletion(with: text) { result in
                switch result {
                case .success(let model):
                    let output = model.choices?.first?.text ?? "";
                    print("Out:"+output)
                    print(result)
                    completion(output)
                case .failure:
                    break;
                }
            }
            } catch {
                print("+++--")
            }
        }
    }
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)

            Button("Request", action: request)
            Image(systemName: isRecording ? "mic" : "mic.slash")
            Button("Start", action: startRecording)
            Button("Stop", action: stopRecording)
            Text(speechRecognizer.transcript)
            VStack {
                ForEach(models, id: \.self) {
                    string in Text(string)
                }
            }
            Button("Send", action: getGptAnswer)
        }
        .onAppear {
            gptModel.setup()
        }
        .padding()
    }
    
    private func startRecording() {
        req = ""
        speechRecognizer.resetTranscript()
        isRecording = true
        speechRecognizer.startTranscribing()
    }
        
    private func stopRecording() {
        isRecording = false
        print(speechRecognizer.transcript)
        req = speechRecognizer.transcript
        speechRecognizer.stopTranscribing()
    }
    
    private func getGptAnswer() {
        print("---")
        print(speechRecognizer.transcript)
        print(req)
        print("---")
        models.append("Me: \(req)")
        gptModel.send(text: req) {
            response in DispatchQueue.main.async {
                self.models.append("ChatGPT:" + response)
            }
            let utterance = AVSpeechUtterance(string: response)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            utterance.rate = 0.5

            
            synthesizer.speak(utterance)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct MessageView: View {
    var message: [String: String]
    
    var messageColor: Color {
        if message["role"] == "user" {
            return .gray
        } else if message["role"] == "assistant" {
            return .green
        } else {
            return .red
        }
    }
    
    var body: some View {
        if message["role"] != "system" {
            HStack {
                if message["role"] == "user" {
                    Spacer()
                }
                
                
                Text(message["content"] ?? "error")
                    .foregroundColor(.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 25).foregroundColor(messageColor))
                    .shadow(radius: 25).cornerRadius(25)
                
                if message["role"] == "assistant" {
                    Spacer()
                }
            }
        }
    }
}
