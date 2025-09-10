#[allow(warnings)]
mod bindings;

use bindings::exports::component::hello::greeter::Guest;

struct Component;

impl Guest for Component {
    fn say_hello(name: String) -> String {
        format!("Hello from Rust, {}!", name)
    }
}

bindings::export!(Component with_types_in bindings);