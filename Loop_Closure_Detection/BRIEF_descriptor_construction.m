%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author : Roger (Aohan) Mei
% Date : 04/20/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function BRIEF_descriptor = BRIEF_descriptor_construction(I)
    %% Initialization
    S_b = 48;
    L_b = 256;
    num_of_feature_points = 128;
    mu = 0;
    sigma1 = 1/5*S_b;
    sigma2 = 2/25*S_b;
    %% Feature detection and extraction
    points = detectFASTFeatures(I);
    [features, valid_points] = extractFeatures(I, points);
%     figure; imshow(I); hold on;
    [B,idx] = maxk(valid_points.Metric,num_of_feature_points);
    valid_feature = zeros(num_of_feature_points, 256);
    valid_points = valid_points.selectStrongest(num_of_feature_points);
    % Construct the descriptor saver into the dimension of
    % 256xnum_of_feature_points
    descriptor_saver = zeros(256,num_of_feature_points);
    for i = 1:num_of_feature_points
        point_x = valid_points.Location(i,2);
        point_y = valid_points.Location(i,1);
        % Patch Construction
        temp_patch = zeros(S_b+1, S_b+1);
        center_x = S_b/2+1;
        center_y = S_b/2+1;
        for delta_x = -S_b/2 : S_b/2
            for delta_y = -S_b/2 : S_b/2
                temp_x = point_x + delta_x;
                temp_y = point_y + delta_y;
                if temp_x<1 | temp_x>313 | temp_y<1 | temp_y>850
                    temp_patch(center_x+delta_x, center_y+delta_y) = 0;
                else
                    temp_patch(center_x+delta_x, center_y+delta_y) = I(temp_x, temp_y);
                end
            end
        end
        % Add a gaussian filter to the patch to denoise it
        temp_patch = imgaussfilt(temp_patch);
        % Construct the modified FAST descriptor of the selected point
        for j = 1:256
            a_i = normrnd(mu,sigma1,2,1);
            b_i = normrnd(a_i,sigma2,2,1);
            a_i = rectify(a_i, S_b);
            b_i = rectify(b_i, S_b);
            if temp_patch(center_x+a_i(1), center_y+a_i(2)) < temp_patch(center_x+b_i(1), center_y+b_i(2))
                descriptor_saver(j,i) = 1;
            else
                descriptor_saver(j,i) = 0;
            end
        end
    end
    BRIEF_descriptor = descriptor_saver;
end
%% Helper Functions
function obj = rectify(obj, S_b)
    for i = 1:2
        if obj(i) < -S_b/2 
            obj(i) = -S_b/2;
        end
        if obj(i) > S_b/2
            obj(i) = S_b/2;
        end
    end
    % Round the sample offset into integers
    obj = round(obj);
end