import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mouaz_app_018/controllers/provider_mz.dart';
import 'package:mouaz_app_018/controllers/tween_mz.dart';

class LoGoMz extends ConsumerWidget {
  const LoGoMz({super.key});
  static double endvaluerotate = 0.0;
  static bool logo = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logo = ref.watch(notifierlogo);

    endvaluerotate = 75.0;
    return MouseRegion(
      onHover: (e) => ref.read(notifierlogo.notifier).onhover(),
      onExit: (e) => ref.read(notifierlogo.notifier).onexit(),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Stack(
            children: [
              Container(
                width: 400,
                height: 75,
                decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.only(topRight: Radius.circular(20)),
                    gradient: LinearGradient(colors: [
                      Colors.deepPurpleAccent,
                      Colors.deepPurpleAccent,
                      Colors.deepPurpleAccent,
                      Colors.black,
                      Colors.transparent,
                    ])),
              ),
              Positioned(top: 25, left: 20, child: mainitem()),
              Positioned(
                  top: 25,
                  left: 20,
                  child: TweenM(
                      type: 'translatex',
                      begin: logo ? 35 : 20,
                      end: 10.0,
                      durationinmilli: 400,
                      child: TweenM(
                          type: 'scalex',
                          begin: 0.0,
                          end: -1.0,
                          durationinmilli: 400,
                          child: mainitem()))),
              Positioned(
                  top: 25,
                  left: 20,
                  child: TweenM(
                      type: 'translatex',
                      begin: 0.0,
                      end: logo ? 0.0 : 40.0,
                      durationinmilli: 400,
                      child: TweenM(
                        type: 'scalex',
                        begin: 0.0,
                        end: logo ? 0.0 : 0.6,
                        durationinmilli: 400,
                        child: TweenM(
                            type: 'rotate',
                            begin: 0.0,
                            end: logo ? 0.0 : 90.0,
                            durationinmilli: 400,
                            child: mainitem()),
                      ))),
              Positioned(
                  top: 25,
                  left: 20,
                  child: TweenM(
                      type: 'translatex',
                      begin: 0.0,
                      end: logo ? 0.0 : 30.0,
                      durationinmilli: 400,
                      child: TweenM(
                        type: 'scalex',
                        begin: 0.0,
                        end: logo ? 0.0 : 0.6,
                        durationinmilli: 400,
                        child: TweenM(
                            type: 'rotate',
                            begin: 0.0,
                            end: logo ? 0.0 : -90.0,
                            durationinmilli: 400,
                            child: mainitem()),
                      ))),
              Positioned(
                  top: 25,
                  left: 20,
                  child: TweenM(
                      type: 'translatex',
                      begin: 0.0,
                      end: logo ? 0.0 : 60.0,
                      durationinmilli: 400,
                      child: TweenM(
                          type: 'rotate',
                          begin: 0.0,
                          end: logo ? 0.0 : 180.0,
                          durationinmilli: 400,
                          child: mainitem()))),
              Positioned(
                  top: 25,
                  left: 20,
                  child: TweenM(
                      type: 'translatex',
                      begin: 0.0,
                      end: logo ? 0.0 : 85.0,
                      durationinmilli: 400,
                      child: TweenM(
                          type: 'rotate',
                          begin: 0.0,
                          end: logo ? 0.0 : 360.0,
                          durationinmilli: 400,
                          child: mainitem()))),
              Positioned(
                  top: 25,
                  left: 20,
                  child: TweenM(
                      type: 'translatex',
                      begin: 0.0,
                      end: logo ? 35.0 : 110.0,
                      durationinmilli: 400,
                      child: TweenM(
                          type: 'rotate',
                          begin: -90.0,
                          end: logo ? -90.0 : 90.0,
                          durationinmilli: 400,
                          child: mainitem()))),
              Positioned(
                  top: 15,
                  left: 20,
                  child: TweenM(
                      type: 'translatex',
                      begin: 0.0,
                      end: logo ? 60.0 : 110.0,
                      durationinmilli: 400,
                      child: TweenM(
                          type: 'opacity',
                          begin: 0.0,
                          end: logo ? 1.0 : 0.0,
                          durationinmilli: 400,
                          child: Text(
                            "معاذ الحوراني \n 1445-2024 \u00a9",
                            style: GoogleFonts.marhey(color: Colors.white),
                          )))),
              Positioned(
                  top: 25,
                  left: 20,
                  child: TweenM(
                      type: 'translatex',
                      begin: 0.0,
                      end: logo ? 200.0 : 130.0,
                      durationinmilli: 400,
                      child: TweenM(
                        type: 'rotate',
                        begin: 90.0,
                        end: logo ? 90.0 : -90.0,
                        durationinmilli: 400,
                        child: mainitem(),
                      ))),
            ],
          ),
        ),
      ),
    );
  }

  Container mainitem() {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(topRight: Radius.circular(25)),
          border: Border(
            left: BorderSide(width: 3, color: Colors.white),
            top: BorderSide(width: 3, color: Colors.white),
            right: BorderSide(width: 3, color: Colors.white),
          )),
      height: 20,
      width: 20,
    );
  }
}
