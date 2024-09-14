% 
% 本 MATLAB 脚本利用计算机视觉工具箱，
% 从视频的每一帧中提取前景物体，并将其与最后一帧的背景合并，生成频闪效果图像。
% 
% email: wusixstx@163.com
% date:  2024.09.14

% 清除工作空间，关闭所有图形窗口，清空命令行
clear all; clc; close all;

% 视频文件的路径和帧范围设置
frame_index = 0;
frame_range = [10, 450];
path = 'experiment.mp4';

% 获取背景和前景数据
[background, foregrounds, frame_range] = get_grounds(path, frame_range);

% 创建图形窗口
figure(1); set(gcf, 'color', 'w');

% 在子图中显示前景、背景和结果图像
subplot(2, 2, 1); 
foreground = combines_transparent(foregrounds, background, linspace(0.1, 1.0, length(foregrounds)));
h.front = imshow(foreground);
title('前景');

subplot(2, 2, 3); 
h.back = imshow(background);
title('背景');


subplot(2, 2, 4); 
result = foreground;
result(foreground == 0) = background(foreground == 0);
h.res = imshow(result);
title('合并结果');

% 在子图的另一个位置创建滑动条和文本标签
subplot(2, 2, 2);
axis off;
title('控制条');

% 起始帧数滑动条
h.ctrl_slider1 = uicontrol('Style', 'slider', ...
    'Min', frame_range(1), 'Max', frame_range(2), 'Value', frame_range(1), ...
    'Units', 'normalized', 'Position', [0.55, 0.8, 0.4, 0.05]);

% 结束帧数滑动条
h.ctrl_slider2 = uicontrol('Style', 'slider', ...
    'Min', frame_range(1), 'Max', frame_range(2), 'Value', frame_range(2), ...
    'Units', 'normalized', 'Position', [0.55, 0.7, 0.4, 0.05]);

% 帧数间隔滑动条
h.ctrl_slider_snap = uicontrol('Style', 'slider', ...
    'Min', 1, 'Max', round(length(foregrounds)/2), 'Value', round((length(foregrounds)/2+1)/2), ...
    'Units', 'normalized', 'Position', [0.55, 0.6, 0.4, 0.05]);

% 添加文本标签
h.text_1 = uicontrol('Style', 'text', 'String', '起始帧数', ...
    'Units', 'normalized', 'Position', [0.55, 0.85, 0.4, 0.05]);

h.text_2 = uicontrol('Style', 'text', 'String', '结束帧数', ...
    'Units', 'normalized', 'Position', [0.55, 0.75, 0.4, 0.05]);

h.text_snap = uicontrol('Style', 'text', 'String', '帧数间隔', ...
    'Units', 'normalized', 'Position', [0.55, 0.65, 0.4, 0.05]);

% 添加按钮
h.ctrl_edit = uicontrol('Style', 'pushbutton', 'String', '编辑前景', ...
    'Position', [0, 0, 100, 50], ... % [x, y, width, height]
    'Callback', @(src, event) buttonCallback_edit(h));

h.ctrl_read = uicontrol('Style', 'pushbutton', 'String', '读取前景/保存', ...
    'Position', [0, 60, 100, 50], ... % [x, y, width, height]
    'Callback', @(src, event) buttonCallback_read(h, background));

% 为滑动条设置回调函数
addlistener(h.ctrl_slider1, 'Value', 'PreSet', @(src, event) updatePlot(h, background, foregrounds));
addlistener(h.ctrl_slider2, 'Value', 'PreSet', @(src, event) updatePlot(h, background, foregrounds));
addlistener(h.ctrl_slider_snap, 'Value', 'PreSet', @(src, event) updatePlot(h, background, foregrounds));

% 正片叠底
function result = multiplyBlending(foregrounds, background, transparents)

% 进行正片叠底合成
background = double(background) / 255;

for i = 1:length(foregrounds)
    foreground = foregrounds{i};
    % 确保前景和背景图像的尺寸相同
    if size(foreground) ~= size(background)
        error('前景和背景图像的尺寸必须相同');
    end

    % 将图像转换为 double 类型
    foreground = double(foreground) / 255;
    
    % 正片叠底合成
    background(foreground~=0) = background(foreground~=0) .* (1-transparents(i)) ...
        + foreground(foreground~=0) .* transparents(i);
end
% 将结果转换回 uint8 类型
result = uint8(background * 255);
end

% 函数：合并前景图像
function res = combines_transparent(foregrounds, background, transparents)
% 进行正片叠底合成
background = double(background) / 255;
mask = false(size(background));

for i = 1:length(foregrounds)
    foreground = foregrounds{i};
    % 确保前景和背景图像的尺寸相同
    if size(foreground) ~= size(background)
        error('前景和背景图像的尺寸必须相同');
    end

    % 将图像转换为 double 类型
    foreground = double(foreground) / 255;
    mask(foreground~=0) = true;
    % 正片叠底合成
    background(foreground~=0) = background(foreground~=0) .* (1-transparents(i)) ...
        + foreground(foreground~=0) .* transparents(i);

end
% 将结果转换回 uint8 类型
res = uint8(background * 255);
res(~mask) = 0;
end

% 按钮的回调函数：编辑前景
function buttonCallback_edit(h)
    imwrite(h.front.CData, 'mask.bmp'); % 保存前景图像
    system('mspaint mask.bmp'); % 使用 Paint 打开图像
    disp('将不需要的前景涂为纯黑，编辑后保存前景！');
end

% 按钮的回调函数：读取前景/保存
function buttonCallback_read(h, background)
    try
        foreground = imread('mask.bmp'); % 尝试读取保存的前景图像
    catch
        foreground = h.front.CData; % 如果读取失败，使用当前前景图像
        fprintf('无前景文件\n');
    end

    % 更新结果图像
    result = foreground;
    result(foreground == 0) = background(foreground == 0);
    
    h.res.CData = result; % 更新显示的结果图像
    imwrite(result, 'res.bmp'); % 保存结果图像

end

% 回调函数：根据滑动条的值更新绘图
function updatePlot(h, background, foregrounds)
    % 获取滑动条的当前值
    sliderValue1 = get(h.ctrl_slider1, 'Value');
    sliderValue1 = max(min(round(sliderValue1 - h.ctrl_slider1.Min), length(foregrounds)), 1);

    sliderValue2 = get(h.ctrl_slider2, 'Value');
    sliderValue2 = max(min(round(sliderValue2 - h.ctrl_slider2.Min), length(foregrounds)), 1);

    sliderValue3 = get(h.ctrl_slider_snap, 'Value');
    snap = round(sliderValue3);
    
    range = [min(sliderValue1, sliderValue2), max(sliderValue1, sliderValue2)];

    % 更新文本标签
    h.text_1.String = ['起始帧数', num2str(range(1))];
    h.text_2.String = ['结束帧数', num2str(range(2))];
    h.text_snap.String = ['间隔帧数', num2str(snap)];

    % 更新前景和结果图像
    index = range(1): snap: range(2);
    foreground = combines_transparent(foregrounds(index), background, linspace(0.1, 1.0, length(index)));
    % result = foreground;
    % result(foreground == 0) = background(foreground == 0);
    result = multiplyBlending(foregrounds(index), background, linspace(0.1, 1.0, length(index)));
    imwrite(result, 'res_trans.bmp'); % 保存结果图像

    h.front.CData = foreground;
    h.res.CData = result;
    drawnow;
end

% 函数：获取背景和前景数据
function [background, foregrounds, range] = get_grounds(path, range)
    videoReader = VideoReader(path); % 创建视频读取对象
    frame_index = 0;
    foreground_cnt = 0;

    % 创建前景检测对象
    foregroundDetector = vision.ForegroundDetector('NumGaussians', 5, 'NumTrainingFrames', 5);

    % 创建播放器以查看背景
    videoPlayer = vision.VideoPlayer('Name', 'Background');
    
    while hasFrame(videoReader)
        % 读取帧
        frame = readFrame(videoReader);

        frame_index = frame_index + 1;
        if frame_index < range(1)
            continue;
        end

        if frame_index > range(2)
            background = frame; % 设置背景图像
            break;
        end

        % 检测前景
        foregroundMask = foregroundDetector(frame);
        
        % 过滤小连通区域
        stats = regionprops('table', foregroundMask, 'Area');
        smallObjects = stats.Area < 10; % 可调整面积阈值
        filteredMask = ismember(labelmatrix(bwconncomp(foregroundMask)), find(~smallObjects));
        
        % 提取背景
        foreground = frame;
        foreground(repmat(~filteredMask, [1, 1, 3])) = 0;
        foreground_cnt = foreground_cnt + 1;
        foregrounds{foreground_cnt} = foreground;

        % 显示前景
        imshow(foreground);
        pause(0.01); % 控制播放速度
    end

    if frame_index < range(2)
        range(2) = frame_index;
        background = frame; % 如果视频帧数不足，设置最后一帧为背景
    end
end
