/*
		TEST Weaver : HilbertWRe, HilbertWIm, HilbertW
*/

(
var size, dur, freq;
var overSample, start;

size = 2048;
overSample = 8;
start = 7 * size - s.options.blockSize;  // offset - to sync cycle

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

{ // real
	HilbertWRe.ar(
		SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		size: size);
}.loadToFloatArray(overSample * dur, s, {
	|arr|
	defer {
		arr = arr.copyRange(start, start+size);
		arr.plot("Real; HilbertWRe; Cosine input", minval: -1, maxval: 1);
	}
}
);

{ // imaginary
	HilbertWIm.ar(
		SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		size: size);
}.loadToFloatArray(overSample * dur, s, {
	|arr|
	defer {
		arr = arr.copyRange(start, start+size);
		arr.plot("Imag; HilbertWIm; Cosine input", minval: -1, maxval: 1);
	}
}
);

{ // [real,imag]
	HilbertW.ar(
		SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		size: size);
}.loadToFloatArray(overSample * dur, s, {
	|arr|
	defer {
		arr = arr.clump(2).flop; // de-interleave
		arr = arr.collect(_.copyRange(start, start+size));
		arr.plot("[real, imag]; HilbertW; Cosine input", minval: -1, maxval: 1);
	}
}
);
)


// quick benchmark - late 2016 Macbook Pro
s.options.numWireBufs_(64*16); // required for 50 instances of HilbertW (pv_brickwall implementation)
s.reboot;
~bus = CtkAudio.play(2);
s.scope(4, ~bus.busnum);
(
d = CtkProtoNotes(
	SynthDef(\hilbertW, {arg outbus;
		var num = 50;
		Out.ar(outbus, Mix.ar(num.collect{HilbertW.ar(SinOsc.ar, 2048, num.reciprocal)}))
	}),

	SynthDef(\hilbertWRe, {arg outbus;
		var num = 50;
		Out.ar(outbus, Mix.ar(num.collect{HilbertWRe.ar(SinOsc.ar, 2048, num.reciprocal)}))
	}),

	SynthDef(\hilbertWIm, {arg outbus;
		var num = 50;
		Out.ar(outbus, Mix.ar(num.collect{HilbertWIm.ar(SinOsc.ar, 2048, num.reciprocal)}))
	})
)
)

// *ar, DelayN & PV_brickwall (size: 2048): 50 instances: avg 9.2%, pk 17.5%, avg fluctuates quite a bit
// note currently uses the DelayN version for the real part...
d[\hilbertW].note().outbus_(~bus.busnum).play
// test individual Re and Im
d[\hilbertWRe].note().outbus_(~bus.busnum).play
d[\hilbertWIm].note().outbus_(~bus.busnum).play


/*
			TEST PDN : HilbertPDN.ar (FOS), HilbertPDN.ar1 (SOS), HilbertPDN.ar2 (SOS, refactored)
*/

// TODO:
// it appears the sin/cos parts are reversed or the imaginary part has its phase inverted
// magnitude response not so great at high freqs... especially the FOS version
(
fork {
	var dur, freq, period;
	var overSample, plotstartcycle, start, plotdur, plotcycles;

	// freq = s.sampleRate/2; // nyquist
	freq = s.sampleRate/4; // half nyquist
	freq = s.sampleRate/3;
	freq = s.sampleRate/5;
	// freq = 4000;
	period = freq.reciprocal;
	overSample = 50; // how many cycles to capture
	plotstartcycle = 1;
	plotcycles = 25;
	start = (plotstartcycle * period * s.sampleRate).asInt -1;  // offset - to sync cycle, start of plot
	dur = period * overSample;  // duration of capture, in seconds
	plotdur = (period * s.sampleRate).asInt * plotcycles;

	{ // [real,imag]
		HilbertPDN.ar(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		);
	}.loadToFloatArray(dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+plotdur));
			arr.plot(format("[real, imag]; HilbertPDN.ar (FOS); Cosine input % Hz", freq), minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // [real,imag]
		HilbertPDN.ar1(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		);
	}.loadToFloatArray(dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+plotdur));
			arr.plot(format("[real, imag]; HilbertPDN.ar1 (SOS); Cosine input % Hz", freq), minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // [real,imag]
		HilbertPDN.ar2(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		);
	}.loadToFloatArray(dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+plotdur));
			arr.plot(format("[real, imag]; HilbertPDN.ar2 (SOS-refactored); Cosine input % Hz", freq), minval: -1, maxval: 1);
		}
		}
	);
}
)

// quick benchmark - late 2016 Macbook Pro
~bus = CtkAudio.play(2);
s.scope(4, ~bus.busnum)
// *ar, FOS: 50 instances: avg 14%, pk 19.5%
{var num = 50; Out.ar(~bus.busnum, Mix.ar(num.collect{HilbertPDN.ar(SinOsc.ar, num.reciprocal)}))}.play
// *ar1, SOS: 50 instances: avg 11%, pk 14.7%
{var num = 50; Out.ar(~bus.busnum, Mix.ar(num.collect{HilbertPDN.ar1(SinOsc.ar, num.reciprocal)}))}.play
// *ar2, SOS, refactored: 50 instances: avg 11%, pk 14.7%
{var num = 50; Out.ar(~bus.busnum, Mix.ar(num.collect{HilbertPDN.ar2(SinOsc.ar, num.reciprocal)}))}.play

// test individual Re and Im
{var num = 50; Out.ar(~bus.busnum, Mix.ar(num.collect{HilbertPDNRe.ar(SinOsc.ar, num.reciprocal)}))}.play
{var num = 50; Out.ar(~bus.busnum, Mix.ar(num.collect{HilbertPDNIm.ar(SinOsc.ar, num.reciprocal)}))}.play





/*
		TEST Hartley : HilbertHRe, HilbertHIm, HilbertH
*/

(
var size, dur, freq;
var overSample, start;

size = 2048;
overSample = 8;
// plot: jump to the 5th cycle, offset further to account for the delay of Convolution2
// start = 5 * size + (((size - 1) / 2).floor).asInt + size - s.options.blockSize;  // offset - to sync cycle
start = 5 * size + ((size/ 2).floor).asInt + size - s.options.blockSize;  // offset - to sync cycle, for kernel normalized to sample delay

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

fork {
	{ // real
		HilbertHRe.ar(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size);
			arr.plot("Real; HilbertHRe; Cosine input", minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // imaginary
		HilbertHIm.ar(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size);
			arr.plot("Imag; HilbertHIm; Cosine input", minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // [real,imag]
		// HilbertH.ar( // all-in-one calculation of coefficients
		HilbertH.ar( // aggregating HilbertHRe and HilbertHIm
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size));
			arr.plot("[real, imag]; HilbertH; Cosine input", minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // [real (convolution), real (delayed)]
		var sig = SinOsc.ar(freq, pi/2); // cosine test, one cycle over fftbuffer size
		[
			HilbertHRe.arConv(sig, size),
			HilbertHRe.ar(sig, size)
		]
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size));
			arr.plot("[real (convolution), real (delayed)]; HilbertHRe; Cosine input", minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // difference between [real (delayed), real (convolution)]
		var sig = SinOsc.ar(freq, pi/2); // cosine test, one cycle over fftbuffer size
		HilbertHRe.ar(sig, size) - HilbertHRe.arConv(sig, size)
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size);
			arr.plot("difference between [real (delayed), real (convolution)]");
		}
	}
	);
}
)



// quick benchmark - late 2016 Macbook Pro
~bus = CtkAudio.play(2);
s.scope(4, ~bus.busnum);

(
p = CtkProtoNotes(
	SynthDef(\hilbertH, {arg outbus;
		var num = 50;
		Out.ar(outbus, Mix.ar(num.collect{HilbertH.ar(SinOsc.ar, 2048, num.reciprocal)}))
	}),

	SynthDef(\hilbertHRe_del, {arg outbus;
		var num = 50;
		Out.ar(outbus, Mix.ar(num.collect{HilbertHRe.ar(SinOsc.ar, 2048, num.reciprocal)}))
	}),

	SynthDef(\hilbertHRe_conv, {arg outbus;
		var num = 50;
		Out.ar(outbus, Mix.ar(num.collect{HilbertHRe.arConv(SinOsc.ar, 2048, num.reciprocal)}))
	}),

	SynthDef(\hilbertHIm, {arg outbus;
		var num = 50;
		Out.ar(outbus, Mix.ar(num.collect{HilbertHIm.ar(SinOsc.ar, 2048, num.reciprocal)}))
	})
)
)

// *ar, DelayL & Convolution2 (size: 2048) : 50 instances: avg 4.7%, pk 17.6%, disparity is LARGE
// note currently uses the DelayL version for the real part...
p[\hilbertH].note().outbus_(~bus.busnum).play
// test individual Re and Im
p[\hilbertHRe_del].note().outbus_(~bus.busnum).play
p[\hilbertHRe_conv].note().outbus_(~bus.busnum).play
p[\hilbertHIm].note().outbus_(~bus.busnum).play