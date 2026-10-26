function im_data = transformChannelData(raw_frames)
% TRANSFORMCHANNELDATA applies 2D IDFT to raw_frames
%   IM_DATA = TRANSFORMCHANNELDATA(RAW_FRAMES) transforms raw images
%     in 3-dimensional image vector RAW_FRAMES with 2-D IDFT.
%    The image data is
%     returned in 3-D vector FILTERED_DATA
% 
%    Author: Josh Marso
% 
    im_data = zeros(size(raw_frames));
    num_frames = size(raw_frames,3);
    for i=1:num_frames  
        im_data(:,:,i) = ifft2((raw_frames(:,:,i)));
    end
end