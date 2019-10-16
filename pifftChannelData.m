function im_data = pifftChannelData(raw_frames)
% TRANSFORMCHANNELDATA applies 2D IDFT to raw_frames
%   IM_DATA = TRANSFORMCHANNELDATA(RAW_FRAMES) transforms raw images
%     in 3-dimensional image vector RAW_FRAMES with 2-D IDFT.
%    The image data is
%     returned in 3-D vector FILTERED_DATA
% 
%    Author: Josh Marso  - transformChannelData (original)
%            Fred J. Frigo - modified to call homodyne function pifft
% 
    im_data = zeros(size(raw_frames));
    [yres, xres, chan] = size(raw_frames);
    start_data = 1;
    end_data = (yres*0.5) + 16 +1;  % use 16 overscans

 
    for i=1:chan
        % im_data(:,:,i) = ifft2(raw_frames(:,:,i));
        partial_data(:,:) = raw_frames(start_data:end_data,:,i);
        homodyne_image = pifft(partial_data);
        im_data(:,:,i) = homodyne_image(:,:);
    end
end