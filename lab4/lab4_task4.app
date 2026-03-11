{application, lab4_task4,
 [
  {description, "Lab4: star topology and parent-children OTP application"},
  {vsn, "1.0.0"},
  {modules, [
      lab4_task4_app,
      lab4_task4_sup,
      lab4_task4_star_server,
      lab4_task4_pc_server
  ]},
  {registered, [
      lab4_task4_sup,
      lab4_task4_star_server,
      lab4_task4_pc_server
  ]},
  {applications, [kernel, stdlib]},
  {mod, {lab4_task4_app, []}}
 ]}.
