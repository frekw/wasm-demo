wit_bindgen::generate!({
    with: { "wasi:clocks/monotonic-clock@0.2.3": generate, },
    with: { "wasi:http/types@0.2.3": generate, },
    with: { "wasi:io/error@0.2.3": generate, },
    with: { "wasi:io/poll@0.2.3": generate, },
    with: { "wasi:io/streams@0.2.3": generate, },
    world: "handler",
});

use exports::wasi::http::incoming_handler::Guest;
use exports::wasi::http::incoming_handler::{
    IncomingRequest, ResponseOutparam
};

use wasi::http::types::{
    Fields, OutgoingResponse, OutgoingBody
};

use component::hello::greeter;

export!(Component);


struct Component;

impl Guest for Component {
        fn handle(_request: IncomingRequest, outparam: ResponseOutparam) {
        let hdrs = Fields::new();
        let resp = OutgoingResponse::new(hdrs);
        let body = resp.body().expect("outgoing response");

        ResponseOutparam::set(outparam, Ok(resp));

        let greeting = greeter::say_hello("WASI");
        
        let out = body.write().expect("outgoing stream");
        out.blocking_write_and_flush(greeting.as_bytes())
            .expect("writing response");

        drop(out);
        OutgoingBody::finish(body, None).unwrap();
    }
}