#!/bin/bash

V="$1"; # should be >RELEASE>_v<n>[.<something>] 
shift
REL=${V%%_v[0-9]*} # will be 106X or 110X 
SAMP=${V%%.*}
PLOTDIR="plots/11_1_X/from${REL}/${V}/val"
SAMPLES="--${V%%.*}"; # remove the ".

W=$1; shift;
while [[ "$W" != "" ]]; do
  case $W in
    run-pgun)
         [[ "$V" == "v1" ]] && SAMPLES="--v1_fat"
         python runRespNTupler.py || exit 1;
         for PU in PU0 PU200; do 
             for X in Particle{Gun,GunPt0p5To5,GunPt80To300}_${PU}; do 
                 ./scripts/prun.sh  runRespNTupler.py $SAMPLES $X ${X}.${V}  --inline-customize 'goGun()'; 
                 grep -q '^JOBS:.*, 0 passed' respTupleNew_${X}.${V}.report.txt && echo " === ERROR. Will stop here === " && exit 2;
             done
         done
         ;;
    plot-pgun)
         for PU in PU0 PU200; do
             NTUPLES=$(ls respTupleNew_Particle{Gun,GunPt0p5To5,GunPt80To300}_${PU}.${V}.root);
             if [[ "$PU" == "PU0" ]]; then
                 python scripts/respPlots.py $NTUPLES $PLOTDIR/ParticleGun_${PU} -w l1pf -p electron,photon,pizero -g  --ymaxRes 0.35 --ptmax 150 -E 3.0
                 python scripts/respPlots.py $NTUPLES $PLOTDIR/ParticleGun_${PU} -w l1pf -p pion,klong,pimix       -g  --ymaxRes 1.2  --ptmax 150 -E 3.0
                 python scripts/respPlots.py $NTUPLES $PLOTDIR/ParticleGun_${PU} -w l1pf -p pion,pizero,pimix      -g  --eta 3.0 5.0  --ymax 3 --ymaxRes 1.5 --label hf  --no-fit 
             else
                 python scripts/respPlots.py $NTUPLES $PLOTDIR/ParticleGun_${PU} -w l1pf -p electron,photon,pizero -g  --ymax 2.5 --ymaxRes 0.6 --ptmax 80 -E 3.0
                 python scripts/respPlots.py $NTUPLES $PLOTDIR/ParticleGun_${PU} -w l1pf -p pion,klong,pimix       -g  --ymax 2.5 --ymaxRes 1.5 --ptmax 80 -E 3.0
                 python scripts/respPlots.py $NTUPLES $PLOTDIR/ParticleGun_${PU} -w l1pf -p pion,pizero,pimix      -g  --ymax 3.0 --ymaxRes 1.5 --ptmax 80 --eta 3.0 5.0 --label hf  --no-fit 
             fi;
         done
         ;;
    stack-pgun-nopu)
         X=ParticleGun_PU0
         f104v0=plots/106X/from104X/v0/val/${X}; 
         me=$PLOTDIR/${X}; 
         for X in pion photon; do for PT in ptbest pt02; do 
            for W in PF Calo; do for G in _gauss; do for R in "" _res; do for E in 13_17 17_25 25_30; do #  
                plot=${X}_eta_${E}${R}${G}-l1pf_${PT}
                python scripts/stackPlotsFromFiles.py --legend="TR" $me/${plot}-comp-${W}.png ${W}${G}${R} v0=$f104v0/$plot.root,Azure+2 ${V}=$me/$plot.root,Green+2;
            done; done; done; done;
         done; done
         ;;
    stack-pgun)
         X=ParticleGun_PU200
         f104v0=plots/106X/from104X/v0/val/${X}; 
         me=$PLOTDIR/${X}; 
         for X in pion photon; do for PT in ptbest pt02; do 
            for W in PF Calo; do for G in _gauss; do for R in "" _res; do for E in 13_17 17_25 25_30; do #  
                plot=${X}_eta_${E}${R}${G}-l1pf_${PT}
                python scripts/stackPlotsFromFiles.py --legend="TR" $me/${plot}-comp-${W}.png ${W}${G}${R} v0=$f104v0/$plot.root,Azure+2 ${V}=$me/$plot.root,Green+2;
            done; done; done; done;
         done; done
         ;;
    run-jets-nopu)
         python runPerformanceNTuple.py || exit 1;
         for X in TTbar_PU0; do
             ./scripts/prun.sh runPerformanceNTuple.py  $SAMPLES $X ${X}.${V}  --inline-customize 'addCHS();addTKs();addSeededConeJets("PF","l1pfCandidates:PF");noPU()'; 
         done
         ;;
    plot-jets-nopu)
         for X in TTbar_PU0; do
            python scripts/respPlots.py perfTuple_${X}.${V}.root $PLOTDIR/${X} -w l1pf -p jet -g
            python scripts/respPlots.py perfTuple_${X}.${V}.root $PLOTDIR/${X} -w l1pf -p jet -g --eta 3.0 5.0 --ptmax 150 --no-eta
            python scripts/respPlots.py perfTuple_${X}.${V}.root $PLOTDIR/${X} -w l1pf -p jet -g --eta 3.5 4.5 --ptmax 150 --no-eta
         done
         ;;
    stack-jets-nopu)
         for X in TTbar_PU0; do
            f104v0=plots/106X/from104X/v0/val/${X}; 
            me=$PLOTDIR/${X}; PT="pt"; X="jet"; 
            for W in PF Calo; do for G in "" _gauss; do for R in "" _res; do for E in 00_13 13_17 17_25 25_30 30_50; do # 
                    plot=${X}_eta_${E}${R}${G}-l1pf_${PT}
                    python scripts/stackPlotsFromFiles.py --legend="TR" $me/${plot}-comp-${W}.png ${W}${G}${R} v0=$f104v0/$plot.root,Azure+2 ${V}=$me/$plot.root,Green+2;
            done; done; done; done;
         done
         ;;
    run-jets)
         python runPerformanceNTuple.py || exit 1;
         for X in {TTbar,VBF_HToInvisible}_PU200; do
             ./scripts/prun.sh runPerformanceNTuple.py  $SAMPLES $X ${X}.${V}  --inline-customize 'addCHS();addTKs();addSeededConeJets()' --max-files 60;
             #break 
         done
         ;;
    plot-jets)
         X=TTbar_PU200
             python scripts/respPlots.py perfTuple_${X}.${V}.root -p jet --no-eta -G $PLOTDIR/${X} -w l1pfpu --ymax 2.2 --ymaxRes 0.9 -E 3.0
         X=VBF_HToInvisible_PU200
             python scripts/respPlots.py perfTuple_${X}.${V}.root -p jet --no-eta -G $PLOTDIR/${X} -w l1pfpu --ymax 2.5 --ymaxRes 0.9 --eta 3.0 5.0 --ptmax 150
             python scripts/respPlots.py perfTuple_${X}.${V}.root -p jet --no-eta -G $PLOTDIR/${X} -w l1pfpu --ymax 2.5 --ymaxRes 0.9 --eta 3.5 4.5 --ptmax 150
         ;;
    stack-jets)
         X=TTbar_PU200
            f104v0=plots/106X/from104X/v0/val/${X}; 
            me=$PLOTDIR/${X}; PT="pt"; X="jet"; 
            for W in PF Calo Puppi; do for G in _gauss; do for R in "" _res; do for E in 00_13 13_17 17_25 25_30; do    
                    plot=${X}_eta_${E}${R}${G}-l1pfpu_${PT}
                    python scripts/stackPlotsFromFiles.py --legend="TR" $me/${plot}-comp-${W}.png ${W}${G}${R} v0=$f104v0/$plot.root,Azure+2 ${V}=$me/$plot.root,Green+2;
            done; done; done; done;
         X=VBF_HToInvisible_PU200
            f104v0=plots/106X/from104X/v0/val/${X}; 
            me=$PLOTDIR/${X}; PT="pt"; X="jet"; 
            for W in PF Calo Puppi; do for G in _gauss; do for R in "" _res; do for E in 30_50 35_45; do 
                    plot=${X}_eta_${E}${R}${G}-l1pfpu_${PT}
                    python scripts/stackPlotsFromFiles.py --legend="TR" $me/${plot}-comp-${W}.png ${W}${G}${R} v0=$f104v0/$plot.root,Azure+2 ${V}=$me/$plot.root,Green+2;
            done; done; done; done;
          ;;
    run-rates)
         python runPerformanceNTuple.py || exit 1;
         for X in {TTbar,VBF_HToInvisible,SingleNeutrino}_PU200; do  
             ./scripts/prun.sh runPerformanceNTuple.py  $SAMPLES $X ${X}.${V}  --inline-customize 'addCHS();addTKs();addRefs(calo=False,tk=False);addSeededConeJets()' --maxfiles 80;
         done
         ;;
    make-jecs)
         X=TTbar_PU200; Y=VBF_HToInvisible_PU200;
         python scripts/makeJecs.py perfNano_${X}.${V}.root perfNano_${Y}.${V}.root  -A  -o jecs.${V}.root 
         ;;
    plot-rates)
         METPLOTS="l1pfpu_metnoref" # l1pfpu_metref,l1pfpu_metrefonly,
         JETPLOTS="l1pfpu_jetnoref" # l1pfpu_jetref,l1pfpu_jetrefonly,
         for X in {TTbar,VBF_HToInvisible}_PU200; do 
             python scripts/jetHtSuite.py perfNano_${X}.${V}.root perfNano_SingleNeutrino_PU200.${V}.root $PLOTDIR/met/$X -j jecs.${V}.root -w $METPLOTS -v met --eta 5.0
         done
         X=TTbar_PU200; 
         python scripts/jetHtSuite.py perfNano_${X}.${V}.root perfNano_SingleNeutrino_PU200.${V}.root $PLOTDIR/ht/$X -j jecs.${V}.root -w $JETPLOTS -v jet1 --eta 2.4
         python scripts/jetHtSuite.py perfNano_${X}.${V}.root perfNano_SingleNeutrino_PU200.${V}.root $PLOTDIR/ht/$X -j jecs.${V}.root -w $JETPLOTS -v jet4 --eta 2.4
         python scripts/jetHtSuite.py perfNano_${X}.${V}.root perfNano_SingleNeutrino_PU200.${V}.root $PLOTDIR/ht/$X -j jecs.${V}.root -w $JETPLOTS -v ht   --eta 2.4
         python scripts/jetHtSuite.py perfNano_${X}.${V}.root perfNano_SingleNeutrino_PU200.${V}.root $PLOTDIR/ht/$X -j jecs.${V}.root -w $JETPLOTS -v ht   --eta 3.5
         python scripts/jetHtSuite.py perfNano_${X}.${V}.root perfNano_SingleNeutrino_PU200.${V}.root $PLOTDIR/ht/$X -j jecs.${V}.root -w $JETPLOTS -v jet4 --eta 3.5
         X=VBF_HToInvisible_PU200; 
         python scripts/jetHtSuite.py perfNano_${X}.${V}.root perfNano_SingleNeutrino_PU200.${V}.root $PLOTDIR/ht/$X -j jecs.${V}.root -w $JETPLOTS -v jet2       --eta 4.7
         python scripts/jetHtSuite.py perfNano_${X}.${V}.root perfNano_SingleNeutrino_PU200.${V}.root $PLOTDIR/ht/$X -j jecs.${V}.root -w $JETPLOTS -v ptj-mjj620 --eta 4.7
         ;;
    stack-rates)
         for X in {TTbar,VBF_HToInvisible}_PU200; do 
            v0=plots/106X/from104X/v0/val/met/${X}; me=$PLOTDIR/met/${X}; W="Puppi"; 
            for plot in metisorate-l1pfpu_eta5.0_pt30_{1,2,5}0kHz; do
                python scripts/stackPlotsFromFiles.py --legend="TR" $me/${plot}-comp-${W}.png ${W}_eff v0=$v0/$plot.root,Azure+2 ${V}=$me/$plot.root,Green+2;
            done
         done
         X=TTbar_PU200; 
         v0=plots/106X/from104X/v0/val/ht/${X}; me=$PLOTDIR/ht/${X}; W="Puppi"; 
         for plot in jet{1,4}isorate-l1pfpu_eta2.4_pt10_20kHz jet4isorate-l1pfpu_eta3.5_pt10_20kHz htisorate-l1pfpu_eta{2.4,3.5}_pt30_20kHz; do
             python scripts/stackPlotsFromFiles.py --legend="TR" $me/${plot}-comp-${W}.png ${W}_eff  v0=$v0/$plot.root,Azure+2 ${V}=$me/$plot.root,Green+2;
         done
         X=VBF_HToInvisible_PU200; 
         v0=plots/106X/from104X/v0/val/ht/${X}; me=$PLOTDIR/ht/${X} W="Puppi"; 
         for plot in jet2isorate-l1pfpu_eta4.7_pt10_{1,2,5}0kHz ptj-mjj620isorate-l1pfpu_eta4.7_pt10_{1,2,5}0kHz; do
             python scripts/stackPlotsFromFiles.py --legend="TR" $me/${plot}-comp-${W}.png ${W}_eff  v0=$v0/$plot.root,Azure+2 ${V}=$me/$plot.root,Green+2;
         done
         ;;
    run-mult)
         python runPerformanceNTuple.py || exit 1;
         for X in {TTbar,VBF_HToInvisible,VBFHToBB}_PU200; do 
             ./scripts/prun.sh runPerformanceNTuple.py  $SAMPLES $X ${X}.${V}_regional  --inline-customize 'respOnly();goRegional()' --maxfiles 24;
         done
         ;;
    plot-mult)
         python runPerformanceNTuple.py || exit 1;
         for X in {TTbar,VBF_HToInvisible,VBFHToBB}_PU200; do 
             python scripts/objMultiplicityPlot.py perfTuple_${X}.${V}_regional.root  $PLOTDIR/multiplicities/${X} -s $X 
         done;
         ;;
  esac;
  W=$1; shift;
done
true
