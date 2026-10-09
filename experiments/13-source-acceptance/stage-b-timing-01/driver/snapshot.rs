//! Validate with the same serde_json parser, retaining bytes rather than a Value tree.
use crate::{Json, Result, decode, natural, text};
use serde::de::{DeserializeSeed, Deserializer, MapAccess, SeqAccess, Visitor};
use std::fmt;

pub(super) struct Snapshot {
    pub step: u64,
    pub status: Json,
    pub raw: String,
}

impl Snapshot {
    pub fn parse(bytes: Vec<u8>) -> Result<Self> {
        let mut decoder = serde_json::Deserializer::from_slice(&bytes);
        let header = Scan::<true>
            .deserialize(&mut decoder)
            .map_err(|e| e.to_string())?;
        decoder.end().map_err(|e| e.to_string())?;
        Ok(Self {
            step: natural(&header.step)?,
            status: header.status,
            raw: text(bytes)?,
        })
    }

    pub fn same_state(&self, other: &Self) -> Result<bool> {
        // Both inputs have already passed complete validation. Different bytes
        // can still be equal (key order, escapes, float spellings, last-key-wins).
        Ok(self.raw == other.raw || decode(self.raw.as_bytes())? == decode(other.raw.as_bytes())?)
    }
}

#[derive(Default)]
struct Header {
    step: Json,
    status: Json,
}

// Do not use IgnoredAny: its skip parser bypasses the Value parser's numeric
// overflow, Unicode/surrogate and recursion checks. Every subtree must pass
// through deserialize_any, even overwritten duplicate keys and unused fields.
struct Scan<const ROOT: bool>;

impl<'de, const ROOT: bool> DeserializeSeed<'de> for Scan<ROOT> {
    type Value = Header;

    fn deserialize<D: Deserializer<'de>>(
        self,
        decoder: D,
    ) -> std::result::Result<Header, D::Error> {
        decoder.deserialize_any(self)
    }
}

impl<'de, const ROOT: bool> Visitor<'de> for Scan<ROOT> {
    type Value = Header;

    fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        formatter.write_str("any valid JSON value")
    }

    fn visit_unit<E>(self) -> std::result::Result<Header, E> {
        Ok(Header::default())
    }
    fn visit_bool<E>(self, _: bool) -> std::result::Result<Header, E> {
        Ok(Header::default())
    }
    fn visit_i64<E>(self, _: i64) -> std::result::Result<Header, E> {
        Ok(Header::default())
    }
    fn visit_u64<E>(self, _: u64) -> std::result::Result<Header, E> {
        Ok(Header::default())
    }
    fn visit_f64<E>(self, _: f64) -> std::result::Result<Header, E> {
        Ok(Header::default())
    }
    fn visit_str<E>(self, _: &str) -> std::result::Result<Header, E> {
        Ok(Header::default())
    }

    fn visit_seq<A: SeqAccess<'de>>(
        self,
        mut sequence: A,
    ) -> std::result::Result<Header, A::Error> {
        while sequence.next_element_seed(Scan::<false>)?.is_some() {}
        Ok(Header::default())
    }

    fn visit_map<A: MapAccess<'de>>(self, mut map: A) -> std::result::Result<Header, A::Error> {
        let mut header = Header::default();
        while let Some(key) = map.next_key::<String>()? {
            match key.as_str() {
                "step" if ROOT => header.step = map.next_value()?,
                "status" if ROOT => header.status = map.next_value()?,
                _ => {
                    map.next_value_seed(Scan::<false>)?;
                }
            }
        }
        Ok(header)
    }
}
