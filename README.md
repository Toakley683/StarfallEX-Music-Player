# StarfallEX - Music Player
### This program will read a GitHub Playlist url to get a playlist, then plays them with Fast Fourier Transform animation

The sine wave at the bottom is the progress bar of the song. this will soon be scrollable.<br>
Along with that you can change many settings such as circle points and more, For more information see below.

# Setting up your own playlist
You need some method of uploading files and music. Upload the .json with the format in the example to a file service and put the download URL in the Starfall <br>
 <br>
You then need to upload your music files somewhere and link them into the .JSON file.

### URLS MUST BE WHITELISTED ACCORDING TO [THIS](https://github.com/thegrb93/StarfallEx/blob/master/lua/starfall/permissions/providers_sh/url_whitelist.lua )

<br>

Some recommended solutions for this.

`Discord` - Automatically removes files after 14 days <br>
`Dropbox` - After many downloads will rate limit for extended period of time <br>
`IPFS` - Difficult to setup, effective for permanant usage <br>

<br>

## <b>Visuals</b>

![MusicPlayer](https://github.com/Toakley683/StarfallEX-Music-Player/assets/101290005/040b0212-5c22-4f45-93ac-aa33210d82e4)

<br>

## <b>Configuration</b>

`CirclePoints` - This is the amount of points around the circle <b>(</b> Default: `384` <b>)</b> <b>`HIGH PERFORMANCE IMPACT`</b> <br>
`LineReactance` - This is how quickly the lines move to the correct position <br>
`LineMagnitude` - This is how far much they move based on input from the music <br>
`LineMaximumMagnitude` - This is how the maximum distance the circle has from the centre <br>
`CircleRadius` - This is the circles START radius <br>

`ProgressBarLines` - This is how many lines the progress renders <b>(</b> Default: `128` <b>)</b> <b>`HIGH PERFORMANCE IMPACT`</b> <br>
`SineScrollMul` - This is how quick the sine waves scrolls <br>
`SineSpectrum` - This is how many peaks there is in the sine wave <b>(</b> Default: `16` <b>)</b> <br>
`SineHeight` - This is how tall the sine waves are <br>
`SineStart` - This is where the sine wave starts ( Negative values start from the bottom ) <br>
`SineNoiseMultiplier` - This is how much randomness is added to the Sine wave <b>(</b> Default: `0` <b>)</b> <br>
`SineFilled` - Whether or not the sine wave fills in the bottom pixels <b>(</b> Default: `false` <b>)</b> <br>

`FFTSplits` - This splits the lines into quadents, think of this as how many spikes you want <b>(</b> Default: `2` <b>)</b> <br>
`Samples` - This is how many samples the FFT calculate has <b>(</b> Default: `6` <b>)</b> <br>

`MaximumHearDistance` - This is the maximum distance people can hear from <b>(</b> Default: `2000` <b>)</b> <br>
`MinimumHearDistance` - This is the minimum distance to hear the music at maximum volume <b>(</b> Default: `1500` <b>)</b> <br>
