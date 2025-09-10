wit_bindgen::generate!({
    world: "greeter-world",
});

use crate::exports::component::hello::greeter::Guest;
use component::hello::greeter;

struct Component;

export!(Component);

impl Guest for Component {
    fn say_hello(name: String) -> String {
        greeter::say_hello(format!("Hello from Rust, {}!", name).as_str())
    }
}