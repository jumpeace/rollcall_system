CREATE TABLE users (
    id integer primary key autoincrement,
    email char(256) unique,
    name char(100),

    is_staff boolean,

    passwd varchar(50),
    salt varchar(20)
);

CREATE TABLE user_tokens (
    id char(64) primary key,
    user_id integer,
    expired_at integer
);

CREATE TABLE departments (
    id integer primary key autoincrement,
    name char(50),
    omit_name char(10)
);

CREATE TABLE buildings (
    num integer primary key
);


CREATE TABLE floors (
    id integer primary key autoincrement,
    building_num integer,
    floor_num integer
);

CREATE TABLE rooms (
    id integer primary key autoincrement,
    floor_id integer,
    room_num integer,
    person_max integer
);

CREATE TABLE students (
    id integer primary key,
    user_id integer,
    grade integer,
    department_id integer,
    room_id integer,
    img_name char(256)
);

CREATE TABLE staffs (
    id integer primary key autoincrement,
    user_id integer,
    is_admin boolean default false
);

CREATE TABLE onduties (
    id integer primary key autoincrement,
    staff_id integer,
    year integer,
    month integer,
    date integer
);

CREATE TABLE rollcalls (
    id integer primary key autoincrement,
    student_id integer,
    onduty_id integer,
    is_student_done boolean default false,
    is_onduty_done boolean default false,
    student_img_name char(256)
);

-- テストデータ
INSERT INTO departments VALUES (1, '機械工学科', 'M');
INSERT INTO departments VALUES (2, '電気電子工学科', 'E');
INSERT INTO departments VALUES (3, '電子制御工学科', 'S');
INSERT INTO departments VALUES (4, '電子情報工学科', 'J');
INSERT INTO departments VALUES (5, '環境都市工学科', 'C');

INSERT INTO buildings VALUES (1);
INSERT INTO buildings VALUES (2);

INSERT INTO floors(building_num, floor_num) VALUES (1, 1);
INSERT INTO floors(building_num, floor_num) VALUES (1, 2);
INSERT INTO floors(building_num, floor_num) VALUES (2, 1);

INSERT INTO rooms(floor_id, room_num, person_max) VALUES (1, 1, 1);
INSERT INTO rooms(floor_id, room_num, person_max) VALUES (2, 2, 2);
INSERT INTO rooms(floor_id, room_num, person_max) VALUES (2, 1, 2);
INSERT INTO rooms(floor_id, room_num, person_max) VALUES (3, 1, 1);