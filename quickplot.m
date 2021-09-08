
% input

roi = 3;
W   = [60 100];


x = props.tm;
props = out;

roidx = find(contains(props.ch,['V-' num2str(roi,'% 04.f')]));

figure
wx = find(x>W(1) & x<W(2));

fun = @(p,x) p(1).*x - p(2);

ry = props.data(roidx,wx);
rx = x(wx);

p(1) = diff(ry([1 end])) / diff(rx([1 end]));
p(2) = ry(1);

% bsx = ry - fun(p,rx);
plot(rx,ry - fun(p,rx));hold on
% plot(rx,ry)
% plot(rx,bsx)