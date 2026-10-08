//! Canonical, arbitrary-length signed decimal prototype integers.
use std::cmp::Ordering;

pub(crate) fn literal(digits: &str, negative: bool) -> String {
    let mut result = String::with_capacity(digits.len() + usize::from(negative));
    if negative && digits != "0" {
        result.push('-');
    }
    result.push_str(digits);
    result
}

pub(crate) fn compare(a: &str, b: &str) -> Ordering {
    let (an, am) = split(a);
    let (bn, bm) = split(b);
    match (an, bn) {
        (true, false) => Ordering::Less,
        (false, true) => Ordering::Greater,
        _ => {
            let order = magnitude_cmp(am, bm);
            if an { order.reverse() } else { order }
        }
    }
}

fn split(s: &str) -> (bool, &str) {
    (s.starts_with('-'), s.strip_prefix('-').unwrap_or(s))
}

fn magnitude_cmp(a: &str, b: &str) -> Ordering {
    a.len().cmp(&b.len()).then_with(|| a.cmp(b))
}

pub(crate) fn arithmetic(a: &str, b: &str, subtract: bool) -> String {
    let (an, am) = split(a);
    let (mut bn, bm) = split(b);
    bn ^= subtract;
    let (negative, digits) = if an == bn {
        (an, add(am, bm))
    } else {
        match magnitude_cmp(am, bm) {
            Ordering::Equal => return "0".into(),
            Ordering::Greater => (an, difference(am, bm)),
            Ordering::Less => (bn, difference(bm, am)),
        }
    };
    let mut result = String::with_capacity(digits.len() + usize::from(negative));
    if negative && digits != *b"0" {
        result.push('-');
    }
    for d in digits.into_iter().rev() {
        result.push(d as char);
    }
    result
}

fn add(a: &str, b: &str) -> Vec<u8> {
    let mut result = Vec::with_capacity(a.len().max(b.len()) + 1);
    let mut carry = 0;
    let mut a = a.bytes().rev();
    let mut b = b.bytes().rev();
    loop {
        let (x, y) = (a.next(), b.next());
        if x.is_none() && y.is_none() {
            break;
        }
        let sum = x.map_or(0, |x| x - b'0') + y.map_or(0, |x| x - b'0') + carry;
        result.push(b'0' + sum % 10);
        carry = sum / 10;
    }
    if carry != 0 {
        result.push(b'0' + carry);
    }
    result
}

fn difference(a: &str, b: &str) -> Vec<u8> {
    let mut result = Vec::with_capacity(a.len());
    let mut b = b.bytes().rev();
    let mut borrow = 0i16;
    for x in a.bytes().rev() {
        let d = (x - b'0') as i16 - b.next().map_or(0, |y| y - b'0') as i16 - borrow;
        borrow = i16::from(d < 0);
        result.push(b'0' + d.rem_euclid(10) as u8);
    }
    while result.len() > 1 && result.last() == Some(&b'0') {
        result.pop();
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn asymmetric_signed_arithmetic() {
        for a in -137i64..=211 {
            for b in [-999i64, -10, -1, 0, 4, 79, 1000] {
                assert_eq!(
                    arithmetic(&a.to_string(), &b.to_string(), false),
                    (a + b).to_string()
                );
                assert_eq!(
                    arithmetic(&a.to_string(), &b.to_string(), true),
                    (a - b).to_string()
                );
                assert_eq!(compare(&a.to_string(), &b.to_string()), a.cmp(&b));
            }
        }
    }

    #[test]
    fn beyond_machine_integer_width() {
        assert_eq!(
            arithmetic("999999999999999999999999999999999999", "2", false),
            "1000000000000000000000000000000000001"
        );
        assert_eq!(
            arithmetic("-1000000000000000000000000000000000000", "17", false),
            "-999999999999999999999999999999999983"
        );
        assert_eq!(literal("0", true), "0");
    }
}
