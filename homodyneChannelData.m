function im_data = homodyneChannelData(raw_frames)
% TRANSFORMCHANNELDATA applies 2D IDFT to raw_frames
%   IM_DATA = TRANSFORMCHANNELDATA(RAW_FRAMES) transforms raw images
%     in 3-dimensional image vector RAW_FRAMES with 2-D IDFT.
%    The image data is
%     returned in 3-D vector FILTERED_DATA
% 
%    Author: Josh Marso  - transformChannelData (original)
%            Fred J. Frigo - modified to call homodyne_reconstruct
% 
    im_data = zeros(size(raw_frames));
    [yres, xres, chan] = size(raw_frames);
    
 
    for i=1:chan
        % im_data(:,:,i) = ifft2(raw_frames(:,:,i));
        im_data(:,:,i) = homodyne_reconstruct(raw_frames(:,:,i));
    end
end