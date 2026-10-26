%%%%%%%%%%%%%%
% Title: sumOfSquares
%
% Author: Josh Marso
%%%%%%%%%%%%%%

function [sos_image] = sumOfSquares(im_data, weights)
    wsImage = zeros(size(im_data,1),size(im_data,2));
    sos_image = uint16(zeros(size(im_data,1),size(im_data,2)));
    num_images = size(im_data,3);
    
    % Nomalize weights
    avg_weight = mean(weights);
    weights = weights./avg_weight;
    
    for i=1 : num_images
        wsImage = wsImage + squeeze(abs((im_data(:,:,i)./weights(i)).^2));
    end
    sos_image = wsImage.^0.5;
    
end