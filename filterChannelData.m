function filtered_data = filterChannelData(raw_frames, ffilter, alternate, nreceivers) 
% FILTERCHANNELDATA applies fermi apodization and an alternation filter to
%   FILTERED_DATA = FILTERCHANNELDATA(RAW_FRAMES, FFILTER) filters raw images
%     in 3-dimensional image vector RAW_FRAMES with 2-D fermi filter in FFILTER.
%    Then chopping (alternations) are applied.  The filtered data is
%     returned in 3-D vector FILTERED_DATA
% 
%    Author: Josh Marso
% 

    % create alteration vectors - fftshift for corresponding acquisition
    % every other element is negated in a row, opposite pattern for next row
    alt = zeros(size(raw_frames(:,:,1)));
    for j=1:size(alt,1)
        for k=1:size(alt,2)
            if( mod(j+k,2) == 0 )
                 alt(j,k)= 1.0;
            else
                 alt(j,k)= -1.0;
            end
        end      
    end
    % all elements in every other row are negated
    alt1 = zeros(size(raw_frames(:,:,1)));
    for j=1:size(alt1,1)
        for k=1:size(alt1,2)
            if( mod(j,2) == 0 )
                 alt1(j,k)= 1.0;
            else
                 alt1(j,k)= -1.0;
            end
        end      
    end
   
    filtered_data = zeros(size(raw_frames));
    num_frames = size(raw_frames,3);
    for i=1:num_frames
        if (nreceivers > 1) && (alternate == 1)
            filtered_data(:,:,i) = raw_frames(:,:,i).*ffilter.*alt;
        else if (nreceivers == 1)
            filtered_data(:,:,i) = raw_frames(:,:,i).*ffilter.*alt1;
        else
            filtered_data(:,:,i) = raw_frames(:,:,i).*ffilter;
        end
    end
end