% read_receiver_weights.m  -  read prescan noise weights from Pfile
%
% Author: Fred J. Frigo
% Date:  Mar 11, 2008
%
%

function [weights] = read_weights( pfile )

% Check to see if pfile name was passed in
if ( nargin == 0 )
   % Enter name of Pfile
   [fname, pname] = uigetfile('*.*', 'Select Pfile');
   pfile = strcat(pname, fname);
end
i = sqrt(-1);

% Open Pfile to read reference scan data.
fid = fopen(pfile,'r', 'ieee-le');
if fid == -1
    err_msg = sprintf('Unable to locate Pfile %s', pfile)
    return;
end

% Determine size of Pfile header based on Rev number
[f_hdr_value, count] = fread(fid, 1, 'real*4');

num_receivers = 16;

% Determine number of channels and recon scale factor.
if (f_hdr_value >= 9.0) & (f_hdr_value < 100.0)
    status = fseek(fid, 168, 'bof');
    rational_scale_factor = fread(fid,1,'real*4');
    status = fseek(fid, 200, 'bof');
    start_recv = fread(fid,1,'integer*2');
    stop_recv = fread(fid,1,'integer*2');
    num_receivers = stop_recv - start_recv + 1;
else
    err_msg = sprintf('Invalid Pfile header revision: %f', f_hdr_value )
end  

if (f_hdr_value == 9.0) |  (f_hdr_value < 12.0) % 11.0 + 12.0
    status = fseek(fid, 792, 'bof');
    [receiver_weights, count] = fread(fid,num_receivers,'real*4');  % 16 Max
elseif (f_hdr_value > 12.0) & (f_hdr_value < 100.0)  % 12.0 and later
    status = fseek(fid, 1508, 'bof');
    prescan_offset = fread(fid,1,'integer*4');
    coil_weight_offset = prescan_offset + 332;
    autoshim_offset = prescan_offset + 320;
    status = fseek(fid, autoshim_offset, 'bof');
    [autoshim, count] = fread(fid,3,'integer*2');
    status = fseek(fid, coil_weight_offset, 'bof');
    [receiver_weights, count] = fread(fid,num_receivers,'real*4');  % 128 Max
else
    err_msg = sprintf('Invalid Pfile header revision: %f', f_hdr_value )
end  
fclose(fid);

sum(receiver_weights);

avg_rec_std = sum(receiver_weights)./size(receiver_weights,1);
weights = receiver_weights./avg_rec_std;

if( num_receivers > 1 )
   figure;
   plot(weights);
   title('Receiver Weights');
end
