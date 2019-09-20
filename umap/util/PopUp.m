%   AUTHORSHIP
%   Primary Developer: Stephen Meehan <swmeehan@stanford.edu> 
%   Math Lead & Secondary Developer:  Connor Meehan <cgmeehan@alumni.caltech.edu>
%   Bioinformatics Lead:  Wayne Moore <wmoore@stanford.edu>
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
%


classdef PopUp < handle
    methods(Static)
        function l=CLOSE_LABEL
            l=['<html>' CytoGate.Get.smallStart ...
                'Close' CytoGate.Get.smallEnd '</html>'];
        end
    end
    properties(Constant)
        PANE_TIMEOUT=1231;
        PANE_LEAVE_BTN=java.awt.Color(.88, .88, .95);
    end
    properties(GetAccess=private)
        busy=[];
        cancelFunction=[];
        main=[];
        msg1=[];
        msg2=[];
    end
    
    properties    
        cancelled=false;
    end
    
    properties(SetAccess=private)
        answer;
        dlg=[];
        biggestD;
        cancelBtn;
        pb;
        label=[];
            priorFig;
    end
    methods
        function incrementProgress(this, by)
            if ~isempty(this.pb)
                if nargin<2
                    by=1;
                end
                this.pb.setValue(by+this.pb.getValue);
            end
        end
        
        function initProgress(this, cnt)
            if cnt<=0
                cnt=1;
            end
            if ~isempty(this.pb)
                this.pb.setMaximum(cnt);
                this.pb.setValue(0)
            else
                this.pb=javaObjectEDT('javax.swing.JProgressBar', 0, cnt);
                D=this.pb.getPreferredSize;
                if ispc
                    rightHeight=20;
                    if D.height<rightHeight
                        D.height=rightHeight;
                        this.pb.setPreferredSize(D);
                    end
                end
                jp=javaObjectEDT('javax.swing.JPanel', ...
                    javaObjectEDT('java.awt.BorderLayout', 2, 8));
                jp.add(this.label, 'Center');
                jp.add(this.pb, 'South');
                this.main.add(jp, 'Center');
                this.stop;
                this.dlg.pack;
            end
        end
        
        function cancel(this)
            this.cancelled=true;
            this.setText('Cancelling...');
            if ~isempty(this.pb)
                mx=this.pb.getMaximum;
                this.pb.setMaximum(mx-2);
            end
        end

        function this=PopUp(msg, where, title, showBusy, cancelFnc, ...
                icon, modal)
            if nargin<7
                modal=false;
                if nargin<6
                    icon=[];
                    if nargin<5
                        cancelFnc=[];
                        if nargin<4
                            showBusy=true;
                            if nargin<3
                                title='Note ....';
                                if nargin<2
                                    where='center';
                                    if nargin<1
                                        msg='One moment please ...';
                                    end
                                end
                            end
                        end
                    end
                end
            end
            this.priorFig=get(0, 'currentFigure');
            jd=javaObjectEDT('javax.swing.JDialog', Gui.ParentFrame);
            if ~isempty(title)
                jd.setTitle(title);
            end
            this.main=javaObjectEDT('javax.swing.JPanel');
            jd.add(this.main);
            this.main.setBorder(javax.swing.BorderFactory.createEmptyBorder (12,12,12,12));
            this.main.setLayout(java.awt.BorderLayout(5,5));
            jl=javaObjectEDT('javax.swing.JLabel');
            %jl=javaObjectEDT('javax.swing.JTextPane');
            %jl.setContentType('text/html');
            %jl.setEditable(false);
            %jl.setOpaque(false);
            jl.setText(msg);
            this.msg1=String.RemoveXml(msg);
            this.msg2=msg;
            if showBusy
                busy=Gui.JBusy('..');
                this.main.add(busy.getComponent, 'West');
            else
                busy=[];
            end
            this.setCancel(cancelFnc);
            this.main.add(jl, 'Center');
            this.dlg=jd;
            this.label=jl;
            if ~showBusy && isempty(icon)
                try
                    icon=Gui.Icon('smallGenie.png');
                catch ex
                    icon=[];
                end
            end
            if ~isempty(icon)
                this.setIcon(icon);
            else
                jd.pack;
            end
            try
                setAlwaysOnTopTimer(jd);
            catch
            end
            Gui.LocateJava(jd, [], where);
            if ~modal
                Gui.SetJavaVisible(jd);
            else
                jd.setModal(true);
            end
            if ~isempty(busy)
                busy.start;
            end
            this.busy=busy;
            drawnow;
        end
        
        function stop(this)
            if ~isempty(this.busy)
                this.busy.stop;
                this.main.remove(this.busy.getComponent);
            end
        end
        
        function close(this, force, refreshOld)
            if nargin<2
                force=false;
            end
            try
                sysPu=CytoGate.Get.pu;
            catch ex
                sysPu=[];
            end
            if force || isempty(sysPu) || this.dlg ~= sysPu.dlg
                this.stop;
                this.dlg.dispose;
                if (nargin<3 || refreshOld) && ~isempty(this.priorFig)
                    if ~ishandle(this.priorFig)
                        this.priorFig=get(0, 'currentFigure');
                    end
                    if ~isempty(this.priorFig)
                        if strcmpi('off', get(this.priorFig, 'visible'))
                            disp('prior figure is invibisble');
                        else
                            figure(this.priorFig);
                        end
                    end
                end
            end
        end
        
        function packIfNeedBe(this)
            this.label.setPreferredSize([])
            drawnow;
            d=this.label.getPreferredSize;
            if isempty(this.biggestD)
                this.biggestD=d;
                this.dlg.pack;
            elseif d.width>this.biggestD.width || ...
                    d.height>this.biggestD.height
                if d.width>this.biggestD.width 
                    this.biggestD.width=d.width;
                end
                if d.height>this.biggestD.height
                    this.biggestD.height=d.height;
                end
                this.label.setPreferredSize(this.biggestD);
                this.dlg.pack;
            else
                difs=[abs(d.width-this.biggestD.width) ...
                    abs(d.height-this.biggestD.height)];
                mx=max(difs);
                if mx<10
                    this.dlg.pack;
                else
                    this.main.invalidate;
                end
            end
        end
        
        function setText(this, msg)
            this.msg1=String.RemoveXml(msg);
            this.msg2=msg;
            this.label.setText(msg);
            this.packIfNeedBe;
        end

        function setText2(this, msg2)
            this.label.setText(['<html>' this.msg1 '<hr><br>' msg2 '</html>']);
            this.packIfNeedBe;
            drawnow;
        end
        
        function setText3(this, msg3)
            N=length(this.msg2);
            if N>15 && strcmpi('</center></html>', this.msg2(end-15:end))
                this.label.setText(['<html>' this.msg2(7:end-16) ...
                    ' ' msg3 '</html>']);
            elseif N>6 && strcmpi('</html>', this.msg2(end-6:end))
                this.label.setText(['<html>' this.msg2(7:end-7)  ...
                    ' ' msg3 '</html>']);
            else
                this.label.setText(['<html>' this.msg2 '<hr>' ...
                    msg3 '</html>']);
            end
            this.packIfNeedBe;
            drawnow;
        end

        function setIcon(this, icon)
            if ischar(icon)
                icon=Gui.Icon(icon);
            end
            this.label.setIcon(icon);
            this.label.setIconTextGap(9);
            this.dlg.pack;
        end

        function setVisible(this, on)
            this.dlg.setVisible(on);
        end
    
        function addCloseBtn(this, txt)
            if nargin<2
                txt='Ok';
            end
            jp=Gui.Panel;
            btn=Gui.NewBtn(txt, @(h,e)shut);
            jp.add(btn);
            this.main.add(jp, 'South');
            this.dlg.pack;
            function shut
                this.dlg.dispose;
            end
        end
        
        function addYesNo(this, cancelToo, defaultAnswer)
            if nargin<2
                cancelToo=true;
            end
            jp=Gui.Panel;
            btnYes=Gui.NewBtn('Yes', @(h,e)close(1));
            jp.add(btnYes);
            btnNo=Gui.NewBtn('No', @(h,e)close(0));
            jp.add(btnNo);
            btnCancel=Gui.NewBtn('Cancel', @(h,e)close(-1));
            root=this.dlg.getRootPane;
            if cancelToo
                jp.add(btnCancel);
                Gui.RegisterEscape(root, btnCancel);
            end
            this.main.add(jp, 'South');
            if nargin>2
                if defaultAnswer==1
                   root.setDefaultButton(btnYes);
                elseif defaultAnswer==-1
                    root.setDefaultButton(btnCancel);
                else
                    root.setDefaultButton(btnNo);
                end
            end
            this.dlg.pack;
            function close(answ)
                this.answer=answ;
                this.dlg.dispose;                
            end
        end
        
        function setCancel(this, cancelFnc)
            if islogical(cancelFnc) && cancelFnc
                cancelFnc=@(h,e)cancel(this);
            end
            this.cancelFunction=cancelFnc;
            if ~isempty(this.cancelFunction)
                c=javaObjectEDT('javax.swing.JButton', 'Cancel');
                ch=handle(c,'CallbackProperties');
                set(ch, 'ActionPerformedCallback', ...
                    this.cancelFunction);
                jp=javaObjectEDT('javax.swing.JPanel');
                jp.add(c);
                this.main.add(jp, 'South');
                this.cancelBtn=c;
            end
        end
        
        function pack(this)
            this.dlg.pack;
        end
        
        function setAlwaysOnTop(this, ok)
            javaMethodEDT( 'setAlwaysOnTop', this.dlg, ok);
            tmr=timer;
            tmr.StartDelay=1.5;
            tmr.TimerFcn=@(h,e)act;
            start(tmr);
            
            function act
                javaMethodEDT( 'setAlwaysOnTop', this.dlg, ok);
            end
        end
    end
    
    methods(Static)
        function KeepPaneBtnText(pane)
            pane.setBackground(PopUp.PANE_LEAVE_BTN)
        end
        
        function TimedClose(jd, pauseSecs, pane)
            if nargin<3
                pane=[];
            end
            closeNow=false;            
            title='';
            firstBtnAl=[];
            clickCount=0;
            
            btn=javaObjectEDT('javax.swing.JButton');
            btnClass=btn.getClass;
            if pauseSecs>2
                tmr=timer;
                tmr.StartDelay=pauseSecs;
                tmr.TimerFcn=@(h,e)closeit;
                start(tmr);
                
                tmr=timer;
                tmr.StartDelay=2;
                pauseSecs=pauseSecs-2;
                tmr.Period=1;
                tmr.TasksToExecute=pauseSecs;
                tmr.ExecutionMode='fixedRate';
                tmr.TimerFcn=@(h,e)countDown;
                title=char(jd.getTitle);
                start(tmr);
            end
            
            firstBtn=[];
            txt1='';
            txt2='';
            try
                if CytoGate.Get.is('showPopUp', true)
                    Gui.SetJavaVisible(jd);
                end
            catch ex
            end
            drawnow;
            function closeit
                if ~closeNow
                    if ~isempty(firstBtnAl)
                        feval(firstBtnAl);                        
                    end
                    if ~isempty(pane)
                        pane.setValue(PopUp.PANE_TIMEOUT);
                    end
                     jd.setVisible(false);
                end
            end
            function click
                clickCount=clickCount+1;
                if clickCount==1
                    stop(tmr);
                    delete(tmr);
                    firstBtn.setText('Close');
                    closeNow=true;
                    jd.setTitle(title);
                else
                    if ~isempty(firstBtnAl)
                        feval(firstBtnAl);
                    end
                    jd.setVisible(false);
                end
            end
            function countDown
                pauseSecs=pauseSecs-1;
                secs=[num2str(pauseSecs) ' secs'];
                jd.setTitle([ title ' (closes in ' secs ')']);
                if ~isempty(pane)
                    if isequal(PopUp.PANE_LEAVE_BTN, pane.getBackground)
                        return;
                    end
                end
                if isempty(firstBtn)
                    firstBtn=Gui.FindFirst(jd, btnClass, 'Ok');
                    if ~isempty(firstBtn)
                        try
                            app=CytoGate.Get;
                        catch ex
                            app.smallStart='<small>';
                            app.smallEnd='</small>';
                        end
                        txt1=firstBtn.getText;
                        if strcmpi('ok', char(txt1))
                            txt1='Closing in';
                        end
                        if isempty(txt1)
                            txt1='';
                        else
                            Html.remove(txt1);
                        end
                        txt1=['<html>' txt1 ' <b>' app.smallStart];
                        txt2=[app.smallEnd '</b></html>']; 
                    end
                    firstBtnAl=get(handle(firstBtn, 'CallbackProperties'), ...
                        'ActionPerformedCallback');
                    firstBtnAls=firstBtn.getActionListeners;
                    nFirstBtnAls=length(firstBtnAls);
                    for i=1:nFirstBtnAls
                        firstBtn.removeActionListener(firstBtnAls(i));
                    end
                    drawnow;
                    set(handle(firstBtn, 'CallbackProperties'), ...
                        'ActionPerformedCallback', @(h,e)click);
                end
                if ~isempty(firstBtn)
                    firstBtn.setText([txt1 secs txt2]);
                    jd.pack;
                end
            end

        end
        function this=New(msg, where, title, showBusy, cancelFnc, icon)
            this=CytoGate.Get.pu;
            if isempty(this) || ~this.dlg.isVisible
                if nargin<6
                    icon=[];
                    if nargin<5
                        cancelFnc=[];
                        if nargin<4
                            showBusy=true;
                            if nargin<3
                                title='Note ....';
                                if nargin<2
                                    where='center';
                                    if nargin<1
                                        msg='One moment please ...';
                                    end
                                end
                            end
                        end
                    end
                end
                if ~showBusy && isempty(icon)
                    icon=Gui.Icon('smallGenie.png');
                end
                this=PopUp(msg,where,title,showBusy,cancelFnc,icon);
            else
                if nargin>=5
                    this.setCancel(cancelFnc);
                end
                if nargin>=3
                    this.dlg.setTitle(title);
                end
                if nargin>=6
                    this.label.setIcon(icon);
                end
                if nargin>=1
                    this.label.setText(msg);
                    this.dlg.pack;
                end
            end
        end
        
        function jMenu=Menu
            jMenu = javaObjectEDT(javax.swing.JPopupMenu);
            ff=jMenu.getFont;
            if ispc
                f2=java.awt.Font('Arial', ff.getStyle, ff.getSize+1);
            else
                f2=java.awt.Font('Arial', ff.getStyle, ff.getSize);
            end
            jMenu.setFont(f2);
        end
        
        function jd=Pane(pane, title, where, javaWin, modal, pauseSecs, ...
                suppressParent)
            isFreeFloating=false;
            if nargin<4 || isempty(javaWin)
                if nargin<7 || ~suppressParent
                    javaWin=Gui.ParentFrame;
                else
                    isFreeFloating=true;
                end
            end
            
            jd=javaMethodEDT('createDialog', pane, javaWin, title);
            jd.setResizable(true);
            app=CytoGate.Get();
            if nargin>4
                jd.setModal(modal);
            end
            %disp(['app.parentCmpForPopup=' app.parentCmpForPopup]);
            if ~isempty(app.parentCmpForPopup)
                javaMethodEDT( 'setLocationRelativeTo', jd, ...
                    app.parentCmpForPopup);
                if nargin>2
                    disp('YES');
                    Gui.LocateJava(jd, app.parentCmpForPopup, where);
                end
            elseif ~isempty(javaWin)
                javaMethodEDT( 'setLocationRelativeTo', jd, javaWin);
                if nargin>2
                    Gui.LocateJava(jd, javaWin, where);
                end
            elseif isFreeFloating
                if nargin>2
                    Gui.LocateJava(jd, Gui.ParentFrame, where);
                end
            end
            if ~ispc %Florian and others note this is a problem 
                setAlwaysOnTopTimer(jd);
            end
            if nargin>=6 && ~isempty(pauseSecs)
                PopUp.TimedClose(jd, pauseSecs, pane);
            else
                try
                    if CytoGate.Get.is('showPopUp', true)
                        Gui.SetJavaVisible(jd);
                    end
                catch ex
                end
                
            end
            CytoGate.Get.closeToolTip;
        end
        
        
        function SetText(pu, txt)
            if ~isempty(pu)
                pu.setText(txt);
            end
        end
        
        function InitProgress(pu, N)
            if ~isempty(pu)
                pu.initProgress(N);
            end
            
        end
        
        function Increment(pu)
            if ~isempty(pu)
                pu.incrementProgress;
            end
        end
    end
end
