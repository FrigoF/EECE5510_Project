%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Title: displayMagnitude.m
% Author: Jason Darby
% Description: Displays the magnitude data for the provided array
%
% @param raw_frams array containing the raw data to be displayed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function displayMagnitude(raw_frames, plotString, logMagnitude)
    num_frames = size(raw_frames,3);
    figure;
    for i=1:num_frames
        if num_frames > 1
            subplot(2,4,i);
        end
        if (logMagnitude == 1)
            imagesc(log(abs(raw_frames(:,:,i))));
        else
            imagesc(abs(raw_frames(:,:,i)));
        end
        colormap('gray');
        title(sprintf('%s, receiver %d', plotString, i));
    end
end