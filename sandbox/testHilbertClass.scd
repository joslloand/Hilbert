/*

FFT analysis

NOTE: FFT returns linear frequency

*/
(
~calcMag = { arg kernel;

	var fftResponse, fftMag;

	// FFT analysis here!
	fftResponse = fft(
		kernel.as(Signal),
		Signal.newClear(kernel.size),
		Signal.fftCosTable(kernel.size)
	);

	// find (& trim magnitude)
	fftMag = fftResponse.magnitude;
	fftMag = fftMag.copyFromStart((kernel.size/2).asInteger);

	fftMag;
};


~calcPha = { arg kernel;

	var fftResponse, fftPha;

	// FFT analysis here!
	fftResponse = fft(
		kernel.as(Signal),
		Signal.newClear(kernel.size),
		Signal.fftCosTable(kernel.size)
	);

	// find (& trim phase)
	fftPha = fftResponse.phase;
	fftPha = fftPha.copyFromStart((kernel.size/2).asInteger);

	fftPha;
};

// // "https://github.com/supercollider-quarks/wslib/blob/master/wslib-classes/Extensions/Collection/extCollection-unwrap.sc"
// ~unwrap = { |lo = -1, hi = 1|
//
// 	var last;
//
// 	last = this[0];
// 	[last] ++ this[1..].collect({ |item|
// 		var out;
// 		out = item.wrap( last + lo, last + hi );
// 		last = out;
// 		out;
// 	});
// }


)

/*
		TEST Weaver : HilbertWRe, HilbertWIm, HilbertW

		single cosine cycle: period = size
*/

(
var size, dur, freq;
var overSample, start;

size = 2048;
overSample = 3;
// plot: jump to the 2nd cycle, to account for "warm up" of Im kernel
start = 2 * size - s.options.blockSize;  // offset - to sync cycle

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

{ // real
	HilbertWRe.ar(
		SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		size: size);
}.loadToFloatArray(overSample * dur, s, {
	|arr|
	defer {
		arr = arr.copyRange(start, start+size-1);
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
		arr = arr.copyRange(start, start+size-1);
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
		arr = arr.collect(_.copyRange(start, start+size-1));
		arr.plot("[real, imag]; HilbertW; Cosine input", minval: -1, maxval: 1);
	}
}
);
)

/*
		TEST Weaver : *arMag, *arPhase, *arRotate, *arShift

		single cosine cycle: period = size
*/

(
var size, dur, freq, angle, shiftFreq;
var overSample, start;

size = 2048;
overSample = 3;
// plot: jump to the 2nd cycle, to account for "warm up" of Im kernel
start = 2 * size - s.options.blockSize;  // offset - to sync cycle

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;
// angle = 0.0;  // in radians
// angle = pi/2;  // in radians
// angle = pi;  // in radians
angle = 3pi/2;  // in radians

shiftFreq = freq;  // return 2 cycles
// shiftFreq = freq.neg;  // return DC

fork {

	{ // magnitude
		HilbertW.arMag(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("HilbertW *arMag; Cosine input", minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // phase
		HilbertW.arPhase(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("HilbertW *arPhase; Cosine input", minval: -pi, maxval: pi);
		}
	}
	);

	0.5.wait;

	{ // phase rotation
		HilbertW.arRotate(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			angle,
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot(format("HilbertW *arRotate; Angle = % degrees", angle.raddeg), minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // frequency shifting
		HilbertW.arShift(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			shiftFreq,
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot(format("HilbertW *arShift; Freq = % Hz", shiftFreq), minval: -1, maxval: 1);
		}
		}
	);

}

)

/*
		TEST Weaver

		Impulse Response
*/
(
var size, dur, freq;
var overSample, start;
var realCoeffs, imagCoeffs;
var plotDbMin, plotDbMax, plotDegMin, plotDegMax;

// kernel size
size = 2048;

overSample = 2;

// plot params
plotDbMin = -60.0;
plotDbMax = 6.0;
plotDegMin = 0.0;
plotDegMax = 180.0;

start = size  - ((size/2).asInt) - s.options.blockSize;  // offset - for kernel normalized to sample delay

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

fork {
	{ // real
		HilbertWRe.ar(
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("Real; HilbertWRe; Impulse input", minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // imaginary
		HilbertWIm.ar(
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("Imag; HilbertWIm; Impulse input", minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // [real,imag]
		HilbertW.ar( // aggregating HilbertWRe and HilbertWIm
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			arr.plot("[real, imag]; HilbertW; Impulse input", minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // plot magnitude - real
		HilbertWRe.ar( // real
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			~calcMag.value(arr).ampdb.plot(
				name: "Real Magnitude Response",
				minval: plotDbMin,
				maxval: plotDbMax
			);
		}
		}
	);

	0.5.wait;

	{ // plot magnitude - imag
		HilbertWIm.ar( // imag
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			~calcMag.value(arr).ampdb.plot(
				name: "Imag Magnitude Response",
				minval: plotDbMin,
				maxval: plotDbMax
			);
		}
		}
	);

	0.5.wait;

	{ // plot magnitude - [real,imag]
		HilbertW.ar( // aggregating HilbertWRe and HilbertWIm
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			[~calcMag.value(arr.at(0)), ~calcMag.value(arr.at(1))].ampdb.plot(
				name: "Real & Imag Magnitude Response",
				minval: plotDbMin,
				maxval: plotDbMax
			);
		}
		}
	);

	0.5.wait;

	{ // plot magnitude - system
		HilbertW.ar( // aggregating HilbertWRe and HilbertWIm
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			((Complex.new(~calcMag.value(arr.at(0)), ~calcMag.value(arr.at(1))).magnitude  / 2.sqrt).ampdb).plot(
				name: "System Magnitude Response",
				minval: plotDbMin,
				maxval: plotDbMax
			);
		}
		}
	);

	0.5.wait;

	{ // plot phase difference - system
		HilbertW.ar( // aggregating HilbertWRe and HilbertWIm
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			(~calcPha.value(arr.at(0)) - ~calcPha.value(arr.at(1))).raddeg.plot(
				name: "System Phase Difference",
				minval: plotDegMin,
				maxval: plotDegMax
			);
		}
		}
	);

	0.5.wait;

}
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
		TEST Hartley : HilbertHRe, HilbertHIm, HilbertH

		single cosine cycle: period = size
*/
(
var size, dur, freq;
var overSample, start;

size = 2048;
overSample = 4;
// plot: jump to the 2nd cycle, to account for "warm up" of Im kernel
start = 2 * size + ((size/ 2).floor).asInt - s.options.blockSize;  // offset - to sync cycle, for kernel normalized to sample delay

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
			arr = arr.copyRange(start, start+size-1);
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
			arr = arr.copyRange(start, start+size-1);
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
			arr = arr.collect(_.copyRange(start, start+size-1));
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
			arr = arr.collect(_.copyRange(start, start+size-1));
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
			arr = arr.copyRange(start, start+size-1);
			arr.plot("difference between [real (delayed), real (convolution)]");
		}
		}
	);
}
)

/*
		TEST Hartley : *arMag, *arPhase, *arRotate, *arShift

		single cosine cycle: period = size
*/

(
var size, dur, freq, angle, shiftFreq;
var overSample, start;

size = 2048;
overSample = 4;
// plot: jump to the 2nd cycle, to account for "warm up" of Im kernel
start = 2 * size + ((size/ 2).floor).asInt - s.options.blockSize;  // offset - to sync cycle, for kernel normalized to sample delay

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;
// angle = 0.0;  // in radians
// angle = pi/2;  // in radians
// angle = pi;  // in radians
angle = 3pi/2;  // in radians

shiftFreq = freq;  // return 2 cycles
// shiftFreq = freq.neg;  // return DC

fork {

	{ // magnitude
		HilbertH.arMag(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("HilbertH *arMag; Cosine input", minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // phase
		HilbertH.arPhase(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("HilbertH *arPhase; Cosine input", minval: -pi, maxval: pi);
		}
	}
	);

	0.5.wait;

	{ // phase rotation
		HilbertH.arRotate(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			angle,
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot(format("HilbertH *arRotate; Angle = % degrees", angle.raddeg), minval: -1, maxval: 1);
		}
	}
	);

	0.5.wait;

	{ // frequency shifting
		HilbertH.arShift(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
			shiftFreq,
			size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot(format("HilbertH *arShift; Freq = % Hz", shiftFreq), minval: -1, maxval: 1);
		}
	}
	);

}

)


/*
		TEST Hartley : HilbertH

		coefficients
*/
(
var size;
var realCoeffs, imagCoeffs;
var plotDbMin, plotDbMax, plotDegMin, plotDegMax;

// kernel size
size = 2048;

// plot params
plotDbMin = -60.0;
plotDbMax = 6.0;
plotDegMin = 0.0;
plotDegMax = 180.0;


// calculate coefficients
realCoeffs = HilbertH.calcRealCoeffs(size);
imagCoeffs = HilbertH.calcImagCoeffs(size);

// plot coefficients
[realCoeffs, imagCoeffs].plot(
	name: "Real & Imag Coefficients",
	minval: -1,
	maxval: 1
);


// plot - magnitude

// real & imag
[~calcMag.value(realCoeffs), ~calcMag.value(imagCoeffs)].ampdb.plot(
	name: "Real & Imag Magnitude Response",
	minval: plotDbMin,
	maxval: plotDbMax
);

// system
((Complex.new(~calcMag.value(realCoeffs), ~calcMag.value(imagCoeffs)).magnitude  / 2.sqrt).ampdb).plot(
	name: "System Magnitude Response",
	minval: plotDbMin,
	maxval: plotDbMax
);

// plot - phase difference
(~calcPha.value(realCoeffs) - ~calcPha.value(imagCoeffs)).raddeg.plot(
	name: "System Phase Difference",
	minval: plotDegMin,
	maxval: plotDegMax
);

)


/*
		TEST Hartley : HilbertHRe, HilbertHIm, HilbertH

		Impulse Response
*/

(
var size, dur, freq;
var overSample, start;
var realCoeffs, imagCoeffs;
var plotDbMin, plotDbMax, plotDegMin, plotDegMax;

// kernel size
size = 2048;

overSample = 2;

// plot params
plotDbMin = -60.0;
plotDbMax = 6.0;
plotDegMin = 0.0;
plotDegMax = 180.0;

start = size - s.options.blockSize;  // offset - for kernel normalized to sample delay

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

fork {
	{ // real
		HilbertHRe.ar(
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("Real; HilbertHRe; Impulse input", minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // imaginary
		HilbertHIm.ar(
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("Imag; HilbertHIm; Impulse input", minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // [real,imag]
		HilbertH.ar( // aggregating HilbertHRe and HilbertHIm
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			arr.plot("[real, imag]; HilbertH; Impulse input", minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // [real (convolution), real (delayed)]
		var sig = Impulse.ar(freq); // imulse test, one pulse over fftbuffer size
		[
			HilbertHRe.arConv(sig, size),
			HilbertHRe.ar(sig, size)
		]
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			arr.plot("[real (convolution), real (delayed)]; HilbertHRe; Impulse input", minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // difference between [real (delayed), real (convolution)]
		var sig = Impulse.ar(freq); // imulse test, one pulse over fftbuffer size
		HilbertHRe.ar(sig, size) - HilbertHRe.arConv(sig, size)
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("difference between [real (delayed), real (convolution)]");
		}
		}
	);

	0.5.wait;

	{ // plot magnitude - real
		HilbertHRe.ar( // real
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			~calcMag.value(arr).ampdb.plot(
				name: "Real Magnitude Response",
				minval: plotDbMin,
				maxval: plotDbMax
			);
		}
		}
	);

	0.5.wait;

	{ // plot magnitude - imag
		HilbertHIm.ar( // imag
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			~calcMag.value(arr).ampdb.plot(
				name: "Imag Magnitude Response",
				minval: plotDbMin,
				maxval: plotDbMax
			);
		}
		}
	);

	0.5.wait;

	{ // plot magnitude - [real,imag]
		HilbertH.ar( // aggregating HilbertHRe and HilbertHIm
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			[~calcMag.value(arr.at(0)), ~calcMag.value(arr.at(1))].ampdb.plot(
				name: "Real & Imag Magnitude Response",
				minval: plotDbMin,
				maxval: plotDbMax
			);
		}
		}
	);

	0.5.wait;

	{ // plot magnitude - system
		HilbertH.ar( // aggregating HilbertHRe and HilbertHIm
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			((Complex.new(~calcMag.value(arr.at(0)), ~calcMag.value(arr.at(1))).magnitude  / 2.sqrt).ampdb).plot(
				name: "System Magnitude Response",
				minval: plotDbMin,
				maxval: plotDbMax
			);
		}
		}
	);

	0.5.wait;

	{ // plot phase difference - system
		HilbertH.ar( // aggregating HilbertHRe and HilbertHIm
			Impulse.ar(freq), // imulse test, one pulse over fftbuffer size
		size: size);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			(~calcPha.value(arr.at(0)) - ~calcPha.value(arr.at(1))).raddeg.plot(
				name: "System Phase Difference",
				minval: plotDegMin,
				maxval: plotDegMax
			);
		}
		}
	);

	0.5.wait;

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


/*
			TEST PDN : HilbertPDN.ar (FOS), HilbertPDN.ar1 (SOS), HilbertPDN.ar2 (SOS, refactored)
*/

// TODO:
// magnitude response not so great at high freqs... especially the FOS version
(
var size, dur, freq;
var overSample, start;

size = 2048;
// size = 512;
// size = 128;
// size = 32;
// size = 8;

overSample = 4;

// plot: adjust "by hand":
// 1) account for "warm up" of Re & Im
// 2) account for non-linear phase response of PDN
start = size + 779;  // size = 2048, sampleRate = 44100
// start = size + 405;  // size = 512, sampleRate = 44100
// start = 2 * size + 33;  // size = 128, sampleRate = 44100
// start = size + 23;  // size = 32, sampleRate = 44100
// start = size + 1;  // size = 8, sampleRate = 44100

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

fork {

	{ // real
		HilbertPDNRe.ar(
			SinOsc.ar(freq, pi/2) // cosine test, one cycle over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot(format("Real; HilbertPDNRe.ar (SOS); Cosine @ % Hz; SR: %", freq, s.sampleRate), minval: -1, maxval: 1);
			// arr.plot("Real; HilbertPDNRe.ar (SOS); Cosine @ % Hz; SR: %", freq, s.sampleRate, minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // imaginary
		HilbertPDNIm.ar(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot(format("Imag; HilbertPDNIm.ar (SOS); Cosine @ % Hz; SR: %", freq, s.sampleRate), minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // [real,imag]
		HilbertPDN.ar(
			SinOsc.ar(freq, pi/2) // cosine test, one cycle over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			arr.plot(format("[real, imag]; HilbertPDN.ar (SOS); Cosine @ % Hz; SR: %", freq, s.sampleRate), minval: -1, maxval: 1);
		}
		}
	);
}
)


/*
		TEST PDN : *arMag, *arPhase, *arRotate, *arShift

		single cosine cycle: period = size
*/

(
var size, dur, freq, angle, shiftFreq;
var overSample, start;

size = 2048;
// size = 512;
// size = 128;
// size = 32;
// size = 8;

overSample = 4;

// plot: adjust "by hand":
// 1) account for "warm up" of Re & Im
// 2) account for non-linear phase response of PDN
start = size + 779;  // size = 2048, sampleRate = 44100
// start = size + 405;  // size = 512, sampleRate = 44100
// start = 2 * size + 33;  // size = 128, sampleRate = 44100
// start = size + 23;  // size = 32, sampleRate = 44100
// start = size + 1;  // size = 8, sampleRate = 44100

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

// angle = 0.0;  // in radians
// angle = pi/2;  // in radians
// angle = pi;  // in radians
angle = 3pi/2;  // in radians

// shiftFreq = freq;  // return 2 cycles
shiftFreq = freq.neg;  // return DC - NOTE: non-linear phase is uncompensated

fork {

	{ // magnitude
		HilbertPDN.arMag(
			SinOsc.ar(freq, pi/2) // cosine test, one cycle over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("HilbertPDN *arMag; Cosine input", minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // phase
		HilbertPDN.arPhase(
			SinOsc.ar(freq, pi/2) // cosine test, one cycle over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("HilbertPDN *arPhase; Cosine input", minval: -pi, maxval: pi);
		}
		}
	);

	0.5.wait;

	{ // phase rotation
		HilbertPDN.arRotate(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		angle);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot(format("HilbertPDN *arRotate; Angle = % degrees", angle.raddeg), minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // frequency shifting
		HilbertPDN.arShift(
			SinOsc.ar(freq, pi/2), // cosine test, one cycle over fftbuffer size
		shiftFreq);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot(format("HilbertPDN *arShift; Freq = % Hz", shiftFreq), minval: -1, maxval: 1);
		}
		}
	);

}

)

/*
		TEST PDN

		Impulse Response
*/
(
var size, dur, freq;
var overSample, start;
var realCoeffs, imagCoeffs;
var plotDbMin, plotDbMax, plotDegMin, plotDegMax;

// kernel size
size = 2048;

overSample = 2;

// plot params
plotDbMin = -60.0;
plotDbMax = 6.0;
// plotDegMin = 0.0;
// plotDegMax = 180.0;
plotDegMin = nil;
plotDegMax = nil;

start = 0;  // offset - for kernel normalized to sample delay

dur = size / s.sampleRate;  // in seconds
freq = dur.reciprocal;

fork {
	{ // real
		HilbertPDNRe.ar(
			Impulse.ar(freq, 0.5) // imulse test, one pulse over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("Real; HilbertPDNRe; Impulse input", minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // imaginary
		HilbertPDNIm.ar(
			Impulse.ar(freq, 0.5), // imulse test, one pulse over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			arr.plot("Imag; HilbertPDNIm; Impulse input", minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // [real,imag]
		HilbertPDN.ar( // aggregating HilbertPDNRe and HilbertPDNIm
			Impulse.ar(freq, 0.5), // imulse test, one pulse over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			arr.plot("[real, imag]; HilbertPDN; Impulse input", minval: -1, maxval: 1);
		}
		}
	);

	0.5.wait;

	{ // plot magnitude - real
		HilbertPDNRe.ar( // real
			Impulse.ar(freq, 0.5), // imulse test, one pulse over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			~calcMag.value(arr).ampdb.plot(
				name: "Real Magnitude Response",
				minval: plotDbMin,
				maxval: plotDbMax
			);
		}
		}
	);

	0.5.wait;

	{ // plot magnitude - imag
		HilbertPDNIm.ar( // imag
			Impulse.ar(freq, 0.5), // imulse test, one pulse over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.copyRange(start, start+size-1);
			~calcMag.value(arr).ampdb.plot(
				name: "Imag Magnitude Response",
				minval: plotDbMin,
				maxval: plotDbMax
			);
		}
		}
	);

	0.5.wait;

	{ // plot magnitude - [real,imag]
		HilbertPDN.ar( // aggregating HilbertPDNRe and HilbertPDNIm
			Impulse.ar(freq, 0.5), // imulse test, one pulse over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			[~calcMag.value(arr.at(0)), ~calcMag.value(arr.at(1))].ampdb.plot(
				name: "Real & Imag Magnitude Response",
				minval: plotDbMin,
				maxval: plotDbMax
			);
		}
		}
	);

	0.5.wait;

	{ // plot magnitude - system
		HilbertPDN.ar( // aggregating HilbertPDNRe and HilbertPDNIm
			Impulse.ar(freq, 0.5), // imulse test, one pulse over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			((Complex.new(~calcMag.value(arr.at(0)), ~calcMag.value(arr.at(1))).magnitude  / 2.sqrt).ampdb).plot(
				name: "System Magnitude Response",
				minval: plotDbMin,
				maxval: plotDbMax
			);
		}
		}
	);

	0.5.wait;

	{ // plot phase difference - system
		HilbertPDN.ar( // aggregating HilbertPDNRe and HilbertPDNIm
			Impulse.ar(freq, 0.5), // imulse test, one pulse over fftbuffer size
		);
	}.loadToFloatArray(overSample * dur, s, {
		|arr|
		defer {
			arr = arr.clump(2).flop; // de-interleave
			arr = arr.collect(_.copyRange(start, start+size-1));
			(~calcPha.value(arr.at(0)) - ~calcPha.value(arr.at(1))).raddeg.plot(
			// (~calcPha.value(arr.at(1)) - ~calcPha.value(arr.at(0))).raddeg.plot( // reversed... which is correct!
				name: "System Phase Difference",
				minval: plotDegMin,
				maxval: plotDegMax
			);
		}
		}
	);

	0.5.wait;

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

