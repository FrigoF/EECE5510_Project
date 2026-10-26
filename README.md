# EECE5510_Project
Magnetic Resonance Image Reconstruction example code in MATLAB.  
Fred J. Frigo, Marquette University, 26-Oct-2026

- ReconMain.m - Performs MR image reconstruction on a raw data file (Pfile).

- ReconZIP4.m - Performs MR image reconstruction on a raw data file & uses zero filling to interpolate by 4.

- ReconHomodyne.m - Performs MR image reconstruction on a raw data file using homodyne technique (Noll et al.)

- carboy - MR raw data file (Pfile) for a 48 cm field of view scan of a carboy filled with nickel chloride solution.

- dqa3 - MR raw data file (Pfile) for a 24 cm field of view scan of the DQA3 phantom.

- displayMagnitude.m - display log magnitude of raw data

- displayPhase.m - display phase of raw data

- fermi.m - Generates Fermi Filter used for data apodization prior to 2D FFT

- filterChannelData.m - Applies Fermi Filter & any required chopping (fftshift) to raw data

- getChannelData.m - Reads raw data and necessary parameters from Pfile

- gradwarp_2D.m - Performs 2D Gradwarp correction to improve spatial accuracy due to nonlinear gradients

- plotp.m - Plot one frame of data from a Pfile

- pifft.m - Homodyne reconstruction.

- pifftChannelData.m - Creates K-space for homodyne reconstruction with desired number of overscans.

- raw_image.m - Displays the magnitude of raw data (K-space)

- read_ge_coeff.m - Initializes spherical harmonic coefficients for gradient coils found in "gw_coils.dat"

- read_weights.m - Reads receiver channel weights from Pfile used in sum of squares coil combination.

- resize_image.m - Resize image for non-symmetric acquisition sizes if necessary.

- sumOfSquares.m - Multi-channel image combination using method described by Roemer

- transformChannelData - Compute 2D FFT
