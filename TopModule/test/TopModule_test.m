clear; clc; close all;

%% Generics & Constants

% pictureWidth    = 200;
% pictureHeight   = 100;
coefWidth       = 8;

pictureNum      = 1;
batchNum        = 1;

%% Input Generation

% coef = zeros(3, 3, batchNum);
% inverse_divisor = zeros(1, batchNum);
% for i = 1 : batchNum
%     while (sum(coef(:, :, i), 'all') <= 0)
%         coef(:, :, i) = randi([-2 ^ (coefWidth - 1), 2 ^ (coefWidth - 1) - 1], 3, 3);
%     end
%     inverse_divisor(i) = round(2 ^ 16 / sum(coef(:, :, i), 'all'));
% end
% 
% threshold   = randi([0 2^14 - 1], 1 , batchNum);
% pictureIn   = randi([0 255], pictureHeight, pictureWidth, pictureNum, batchNum);
coef            = [1 1 1;
                   1 1 1;
                   1 1 1];
inverse_divisor = round(2 ^ 16 / sum(coef, 'all'));
threshold       = 450;

pictureIn       = double(imread("EyeTest.png"));
% pictureIn       = double(rgb2gray(pictureIn));
pictureWidth    = size(pictureIn, 2);
pictureHeight   = size(pictureIn, 1);

inputFile = fopen('input_data.txt', 'w');
fprintf(inputFile, [repmat('%-10d\t', 1, 9 + 3 + 2) '\n'], zeros(9 + 3 + 2, 100));

for i = 1:batchNum
    fprintf(inputFile, [repmat('%-10d\t', 1, 9 + 3 + 2) '\n'], [reshape(coef(:, :, i)', 9, 1); inverse_divisor(i); threshold(i); 1; 0; 0]);
    for j = 1:pictureNum
        fprintf(inputFile, [repmat('%-10d\t', 1, 9 + 3 + 2) '\n'], [zeros(9 + 3, pictureWidth * pictureHeight); reshape(pictureIn(:, :, j, i)', 1, pictureWidth * pictureHeight); ones(1, pictureWidth * pictureHeight)]);
    end
    fprintf(inputFile, [repmat('%-10d\t', 1, 9 + 3 + 2) '\n'], zeros(9 + 3 + 2, 50));
end

fprintf(inputFile, [repmat('%-10d\t', 1, 9 + 3 + 2) '\n'], zeros(9 + 3 + 2, 100));
fclose(inputFile);

%% Matlab Ouput

coefx           = [-1 0 1; -2 0 2; -1 0 1];
coefy           = [-1 -2 -1; 0 0 0; 1 2 1];
dataOutMatlab   = zeros(pictureHeight - 4, pictureWidth - 4, pictureNum, batchNum);

for i = 1:batchNum
    for j = 1:pictureNum
        filtered                    = round(conv2(pictureIn(:, :, j, i), rot90(coef(:, :, i), 2), 'valid') * inverse_divisor(i) / (2^16));
        filtered(filtered < 0)      = 0;
        filtered(filtered > 255)    = 255;

        Gx              = conv2(filtered, rot90(coefx, 2), 'valid'); 
        Gy              = conv2(filtered, rot90(coefy, 2), 'valid'); 
        sobelFiltered   = abs(Gx) + abs(Gy);

        sobelFiltered(sobelFiltered < threshold(i))     = 0;
        sobelFiltered(sobelFiltered >= threshold(i))    = 1;
        dataOutMatlab(:, :, j, i)                       = sobelFiltered;
    end 
end

%% Simulation

appendText = [' -GpictureWidth=' num2str(pictureWidth) ' -GpictureHeight=' num2str(pictureHeight) ' -GcoefWidth=' num2str(coefWidth)];
fid = fopen('../tcl/TopModule.tcl', 'r');

lines = {};
while ~feof(fid)
    line = fgetl(fid);
    if contains(line, 'vsim') 
        line = [line, appendText]; 
    end
    lines{end+1} = line; 
end
fclose(fid);

fid = fopen('run.tcl', 'w');
fprintf(fid, '%s\n', lines{:});
fclose(fid);

!start vsim -do run.tcl
pause

%% Output Validation

outputFile = fopen('output_data.txt', 'r');
dataOutVhdl = fscanf(outputFile, '%d');
fclose(outputFile);

dataOutVhdl_r   = zeros(pictureHeight - 4, pictureWidth - 4, pictureNum, batchNum);
for i = 1 : batchNum
    for j = 1 : pictureNum
        dataOutVhdl_r(:, :, j, i) = reshape(dataOutVhdl(((i - 1) * pictureNum + (j - 1)) * (pictureHeight - 4) * (pictureWidth - 4) + 1 :((i - 1) * pictureNum + (j)) * (pictureHeight - 4) * (pictureWidth - 4)), pictureWidth - 4, pictureHeight - 4)';
    end
end
error = dataOutVhdl_r ~= dataOutMatlab;

plot(error(:))
title('Error')

if sum(error, 'all') == 0
    disp("No Error Occurred")

    figure(Name="Results")
    subplot(1, 2, 1)
    imshow(dataOutVhdl_r)
    title("VHDL")

    subplot(1, 2, 2)
    imshow(dataOutMatlab)
    title("Matlab")
else
    disp("Error Occurred")
end