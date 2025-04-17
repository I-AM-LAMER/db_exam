create table students (
    id serial primary key,
    first_name text,
    last_name text,
    group_id int references student_groups(id)
);

create table student_groups (
    id serial primary key,
    name text
);

create table disciplines (
    id serial primary key,
    name text
);

create table schedule (
    id serial primary key,
    discipline_id int references disciplines(id),
    group_id int references student_groups(id),
    time_start timestamp,
    time_end timestamp
);

create table notifications (
    id serial primary key,
    student_id int references students(id),
    created_at timestamp default now(),
    message text,
    is_read boolean default false
);

create or replace function send_notification()
  returns trigger
  language plpgsql
as
$body$
declare
  _student_group_id int;
  _discipline_id int;
  _new_start_time timestamp;
  _new_end_time timestamp;
  _old_start_time timestamp;
  _old_end_time timestamp;
begin  
  if tg_op in ('INSERT') then
    _student_group_id = new.student_group_id;
    _discipline_id = new.discipline_id;
    _new_start_time = new.start_time;
    _new_end_time = new.end_time;

    insert into notification (student_id, created, payload)
      select student.id, now(), 'В расписании для вашей группы добавлено новое занятие ' || discipline.title::text || ', которое пройдет с ' || _new_start_time::text || ' по ' || _new_end_time::text || '.'
        from discipline, student
        where discipline.id = _discipline_id and student.student_group_id = _student_group_id;
    return null;
  elseif tg_op in ('UPDATE') then
    _student_group_id = new.student_group_id;
    _discipline_id = new.discipline_id;
    _old_start_time = old.start_time;
    _old_end_time = old.end_time;
    _new_start_time = new.start_time;
    _new_end_time = new.end_time;

    if new.discipline_id != old.discipline_id or new.student_group_id != old.student_group_id then
      raise exception 'При изменении рассписания не допускается изменению дисциплина или группа студентов!';
    end if;

    insert into notification (student_id, created, payload)
      select student.id, now(), 'В расписании для вашей группы произошло изменение занятия ' || discipline.title::text || ' время начала ' || _old_start_time::text || ', окончание ' || _old_end_time::text || '. Новое время начала ' || _new_start_time::text || ', новое время окончания ' || _new_end_time::text || '.'
        from discipline, student
        where discipline.id = _discipline_id and student.student_group_id = _student_group_id;
    return null;
  elseif tg_op in ('DELETE') then
    _student_group_id = old.student_group_id;
    _discipline_id = old.discipline_id;
    _old_start_time = old.start_time;
    _old_end_time = old.end_time;

    insert into notification (student_id, created, payload)
      select student.id, now(), 'В расписании для вашей группы занятие ' || discipline.title::text || ' время начала ' || _old_start_time::text || ', время окончания ' || _old_end_time::text || ' ОТМЕНЕНО!'
        from discipline, student
        where discipline.id = _discipline_id and student.student_group_id = _student_group_id;
    return old;
  end if;
end;
$body$;



create or replace trigger send_notification_trigger
  after insert or update or delete on schedule
  for each row
  execute procedure send_notification();



insert into schedule (discipline_id, student_group_id, start_time, end_time)
values
  ('1', '1', '2025-04-16 10:45:00', '2025-04-16 12:15:00');

update schedule set start_time = now(), end_time = now() where id = 13;

delete from schedule where id = 15;

select * from schedule;
-- delete from schedule;

select * from notification where student_id = 1;
-- delete from notification;
