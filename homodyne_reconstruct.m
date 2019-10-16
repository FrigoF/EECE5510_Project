function [new_image] = homodyne_reconstruct(orig_kspace);

% ============================================================================================
%  Homodyne reconstruction algorithm
%  
%  usage:    perform iterative homodyne reconstruction with partial k-space.  
%
%  inputs:   partial k-space (zero padded)
%            
%
%  output    homodyne reconstructed image
%
%  Fred J. Frigo - Oct 31, 2017
%
% ============================================================================================

%  step 1: Initial homodyne parameters
num_iterations = 1;
[xres, yres] = size(orig_kspace);
start_data = 1;
end_data = (yres*0.5) + 16 +1;  % use 16 overscans

%  step 1:  create a truncated and zero padded version of the measured k-space
%  --------------------------------------------------------------------------------------------
kspace_lowfreq = zeros(xres,yres);
kspace_lowfreq(:,yres-end_data+1:end_data) = orig_kspace(:,yres-end_data+1-start_data+1:end_data-start_data+1);

%  step 2:  generate a low frequency phase image
%  --------------------------------------------------------------------------------------------
image_lowfreq = ifft2(fftshift(kspace_lowfreq)); 
phase_lowfreq = angle(image_lowfreq);


%  step 3:  zero pad the original data set accordingly and do a 2D FFT
%  --------------------------------------------------------------------------------------------
orig_kspace_zeropad = zeros(xres,yres);
orig_kspace_zeropad(:,start_data:end_data) = orig_kspace(:,start_data:end_data);
orig_image_zeropad = ifft2(fftshift(orig_kspace_zeropad)); 

% prepare for iterations
last_image = orig_image_zeropad;
inter_image = zeros(xres,yres);
inter_kspace = zeros(xres,yres);

for iteration = 1:num_iterations
   
  % step 4:  create intermediate complex image
  % -------------------------------------------
  inter_image = abs(last_image) .* exp(sqrt(-1)*phase_lowfreq);

  % step 5:  create intermediate kspace data
  % -------------------------------------------
  inter_kspace = fft2(inter_image); % removed double fftshift

  % step 6:  substitute the intermediate kspace into the original zeropadded kspace
  % --------------------------------------------------------------------------
  new_kspace = orig_kspace_zeropad;
  new_kspace(:,1:start_data-1) = inter_kspace(:,1:start_data-1);
  new_kspace(:,end_data+1:yres) = inter_kspace(:,end_data+1:yres);

  % step 6.5:  if last iterations, apply a Hanning filter to merge the two data sets 
  % --------------------------------------------------------------------------------
  if(iteration == num_iterations)
     u = 10;
     for i=end_data-u:end_data
        new_kspace(:,i) = 0.5*(orig_kspace_zeropad(:,i)*(1+cos(pi*(i-end_data+u)/u)) +  inter_kspace(:,i)*(1+cos(pi + pi*(i-end_data+u)/u)));
     end
     for i=start_data:start_data+u
        new_kspace(:,i) = 0.5*(orig_kspace_zeropad(:,i)*(1+cos(pi + pi*(i-start_data)/u)) +  inter_kspace(:,i)*(1+cos(pi*(i-start_data)/u)));
     end
  end

  % step 7:  create the new complex image for this iteration 
  % --------------------------------------------------------
  new_image =  ifft2(new_kspace);  % removed fftshift

  % step 8:  examine convergence
  % ----------------------------
  convergence(iteration) = sum(sum(abs(new_image - last_image)))

  % step 9:  prepare for next iteration
  % -----------------------------------
  last_image = new_image;

end


if (0)

figure
subplot(1,2,1)
imagesc(abs(image_lowfreq))
title('orig image zeropad')
axis image
subplot(1,2,2)
imagesc(abs(new_image))
title('homodyne reconstruct')
axis image
colormap gray
% wl_gray

end




