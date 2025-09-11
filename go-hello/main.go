//go:generate go tool wit-bindgen-go generate --world greeter-go --out internal ./component:hello.wasm

package main

import "example.com/internal/component/hello/greeter"

func init() {
	greeter.Exports.SayHello = func(name string) string {
		return "Hello from Go: " + name
	}
}

func main() {}
