# Calibration

Colour can't be derived from specs, because no matrix or gamma data is published. It has to come from
footage. Put clips in `calibration/footage/` (ignored by git).

Best to worst:

1. **Your own camera:** shoot a colour chart and a grey ramp with each scene file and record the
   settings. Fit the matrix and curve, then a LUT for what's left.
2. **Footage with a chart in it:** same, but the settings are unknown.
3. **Matched scenes:** real clips with similar light to a game location. Tune by eye and scopes.

## Lenses

For each lens, shoot straight lines across the frame (a grid, brick wall or building) and a bright,
even surface. These give the radial curve and the corner darkening. Do it at the widest zoom and at
any zoom you'd really use.

## Notes

Always note the camera, mode, scene file, gamma, matrix, and detail settings. Results go in the
profile's matrix and curve values, with their tag changed from `guess`.
