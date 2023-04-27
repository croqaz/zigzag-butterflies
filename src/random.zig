const rand = @import("std").rand;
const RndGen = rand.DefaultPrng;
var prng: RndGen = undefined;

pub fn initRandom(seed: u32) void {
    prng = RndGen.init(seed);
}

pub fn random() rand.Random {
    return prng.random();
}
