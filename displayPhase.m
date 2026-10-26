%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Title: displayPhase.m
% Author: Fred J. Frigo
% Description: Displays the phase data for the provided array
%
% @param raw_frames array containing the raw data to be displayed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function displayPhase(raw_frames, plotString)
    num_frames = size(raw_frames,3);
    num_rows = size(raw_frames,2);
    num_cols = size(raw_frames,1);
    figure;
    for i=1:num_frames
        phase_image = angle(raw_frames(:,:,i));
        mag_image = abs(raw_frames(:,:,i));
        mask_image = (mag_image > 0.02); %create mask image with threshold
        mask_phase = mask_image.*phase_image;
        for j=1:num_rows
            unwrap_phase(j,:)=unwrap(mask_phase(j,:));
        end
        if (num_frames > 1) % for multi-coil, plot each channel image
            subplot(2,4,i);
        end
        imagesc(unwrap_phase.*mask_image);
        colormap('jet');
        title(sprintf('%s, receiver %d', plotString, i));
    end
end