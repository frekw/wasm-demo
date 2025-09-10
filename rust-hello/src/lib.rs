wit_bindgen::generate!({
    world: "greeter-world",
});

use crate::exports::component::hello::greeter::Guest;

struct Component;

export!(Component);

impl Guest for Component {
    fn say_hello(name: String) -> String {
        format!("Hello from Rust, {}!", name)
    }
}