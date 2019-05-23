import Cocoa

// Provider is used to pull data from the server. Input data for the server are not handled here.

class Provider<Value> {

    private var value: Value?
    private var listeners: [(Value) -> Void] = []
    private let worker: (@escaping (Value) -> Void) -> Void

    init(worker: @escaping (@escaping (Value) -> Void) -> Void) {
        self.worker = worker
    }

    func addListener(listener: @escaping ((Value) -> Void)) {
        listeners.append(listener)
        if let value = self.value {
            // If there is a value already, call the new listener streight away.
            listener(value)
        }
    }

    func refresh() {
        worker { (value) in
            self.value = value
            self.listeners.forEach { $0(value) }
        }
    }
}

// Example of content displaying VC.  This is where the spinner view and content view live.

class Test {

    // This manages data IN from the server
    private let viewModelProvider: Provider<String>

    init(viewModelProvider: Provider<String>) {
        self.viewModelProvider = viewModelProvider
        // Event listening pattern make the provider the ideal place to embed push behaviours
        // (e.g. push notifications, silent push or server polling).
        self.viewModelProvider.addListener { [weak self] (value) in
            guard let `self` = self else { return }
            self.updateViewSomehow(with: value)
        }
    }

    func updateViewSomehow(with value: String) {
        print(value)
    }
}

// Builder to incapsulate the provider

struct Builders {

    enum Module {
        case test
    }

    // This would be a UIViewController in iOS
    func build(module: Builders.Module) -> AnyObject {
        switch module {
        case .test:
            print("Building Test...")
            return self.buildTest()
        }
    }

    private func buildTest() -> Test {

        func worker(callback: @escaping ((String) -> Void)) {
            DispatchQueue.global(qos: .background).async {
                print("Test data requested...")
                sleep(2)
                callback("Test data obtained")
            }
        }
        let provider = Provider<String>(worker: worker)
        provider.refresh() // Refresh can be called by anyone with knowlege of the provider the builder and the VC only in this case.
        let module = Test(viewModelProvider: provider)
        print("Test built")
        return module
    }
}

let testModule = Builders().build(module: .test)

// Push behaviour.  WIP.  Stay tuned...
// ...
