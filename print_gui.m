folder = "E:\Renan\Cerebral AT Priming\22-04-07";
trial = "106_stim";

fpath = fullfile(folder,trial);

fig = gcf;
fig.PaperPosition = [0 0 1920 1080];
fig.PaperUnits = 'points';
print(fig,fpath,'-r300','-dpdf','-painters','-bestfit')