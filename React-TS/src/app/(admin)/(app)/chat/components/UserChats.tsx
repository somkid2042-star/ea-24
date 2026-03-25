import img3 from '@/assets/images/small/img-3.jpg';
import img5 from '@/assets/images/small/img-5.jpg';
import avatar1 from '@/assets/images/user/avatar-1.png';
import avatar7 from '@/assets/images/user/avatar-7.png';
import SimplebarClient from '@/components/client-wrapper/SimplebarClient';

import { Link } from 'react-router';
import {
  LuChevronsLeft,
  LuImage,
  LuMic,
  LuPanelRightOpen,
  LuPhone,
  LuSearch,
  LuSend,
  LuVideo,
} from 'react-icons/lu';

type MessageContent = {
  id: number;
  text?: string;
  images?: string[];
};
type Message = {
  id: number;
  sender: 'me' | 'other';
  text?: string;
  images?: string[];
  avatar: string;
  contents?: MessageContent[];
};

const messages: Message[] = [
  {
    id: 1,
    sender: 'other',
    text: 'Sure, I have my pen and paper ready.',
    avatar: avatar7,
  },
  {
    id: 2,
    sender: 'me',
    text: 'Great. Please read the notes of our last meeting for us.',
    avatar: avatar1,
  },
  {
    id: 3,
    sender: 'other',
    avatar: avatar7,
    contents: [
      {
        id: 1,
        text: 'Okay. First, we talked about the budget for next year.',
        images: [img3, img5],
      },
      {
        id: 2,
        text: 'I will budget is getting smaller every year.',
      },
      {
        id: 3,
        text: 'Second, we talked about the new products we are going to selling.',
      },
      {
        id: 4,
        text: 'O.K. Third, we talked about the profits that we had last month. And fourth, we talked about the bills we had to pay.',
      },
    ],
  },
  {
    id: 7,
    sender: 'me',
    text: 'Sorry, William. O.K. We have a few things to talk about today. would you like to give your report.',
    avatar: avatar1,
  },
  {
    id: 8,
    sender: 'other',
    text: 'Yes, thank you 🤩. I have a sales graph I would like to show everyone. This shows how well we are selling our products this year.',
    avatar: avatar7,
  },
  {
    id: 9,
    sender: 'me',
    text: 'Thank you 🤩, William. Very good. Tom, do you have anything to tell everyone.',
    avatar: avatar1,
  },
];

const UserChats = () => {
  return (
    <div className="w-full border-e border-default-200 rounded">
      <div className="card-body">
        <div className="gap-3 flex justify-between">
          <div className="flex gap-3.5 items-center">
            <button
              className="lg:hidden size-8 rounded-md flex justify-center items-center bg-default-100"
              aria-haspopup="dialog"
              aria-expanded="false"
              aria-controls="hs-offcanvas-left"
              data-hs-overlay="#hs-offcanvas-left"
            >
              <LuChevronsLeft className="size-4 text-default-500 hover:text-primary" />
            </button>

            <div className="rounded-full size-10 bg-default-100">
              <img src={avatar7} alt="user" className="h-10 rounded-full" />
            </div>

            <div>
              <h6 className="text-default-800 mb-1 font-bold text-sm">William Heineman</h6>
              <p className="text-xs text-default-500">NextJS Developer</p>
            </div>
          </div>

          <div className="flex gap-3">
            <button className="btn rounded-full size-9 hover:bg-primary/10 hover:text-primary transition-all">
              <LuPhone className="size-5" />
            </button>
            <button className="btn rounded-full size-9 hover:bg-primary/10 hover:text-primary transition-all">
              <LuVideo className="size-5" />
            </button>
            <button className="btn rounded-full size-9 hover:bg-primary/10 hover:text-primary transition-all">
              <LuSearch className="size-5" />
            </button>
            <button className="btn rounded-full size-9 hover:bg-primary/10 hover:text-primary transition-all">
              <LuPanelRightOpen className="size-5" />
            </button>
          </div>
        </div>
      </div>

      <SimplebarClient className="h-[calc(100vh-340px)]">
        <div className="card-body bg-default-50">
          <div className="flex flex-col gap-5">
            {messages.map(msg =>
              msg.sender === 'other' ? (
                <div key={msg.id} className="flex gap-3 items-end">
                  <Link
                    to="#"
                    className="flex items-center justify-center text-sm font-semibold rounded-full size-9 bg-default-200"
                  >
                    <img
                      src={msg.avatar}
                      alt="avatar"
                      className="object-cover rounded-full h-9"
                      width={36}
                      height={36}
                    />
                  </Link>

                  <div className="flex flex-col gap-3">
                    {msg.text && (
                      <div className="w-92 p-4 card text-default-700 text-sm">
                        {msg.text}
                        {msg.images && (
                          <div className="grid grid-cols-3 gap-4 mt-4">
                            {msg.images.map((img, i) => (
                              <Link key={i} to="#">
                                <img src={img} alt="chat-img" className="rounded-md" />
                              </Link>
                            ))}
                          </div>
                        )}
                      </div>
                    )}

                    {msg.contents &&
                      msg.contents.map(block => (
                        <div key={block.id} className="w-92 p-4 card text-default-700 text-sm">
                          {block.text}
                          {block.images && (
                            <div className="grid grid-cols-3 gap-4 mt-4">
                              {block.images.map((img, i) => (
                                <Link key={i} to="#">
                                  <img src={img} alt="chat-img" className="rounded-md" />
                                </Link>
                              ))}
                            </div>
                          )}
                        </div>
                      ))}
                  </div>
                </div>
              ) : (
                <div key={msg.id} className="flex gap-3 justify-end items-end">
                  <div className="flex flex-col gap-3 items-end">
                    {msg.text && (
                      <div className="w-92 p-4 card text-default-700 text-sm">{msg.text}</div>
                    )}

                    {msg.contents &&
                      msg.contents.map(block => (
                        <div key={block.id} className="w-92 p-4 card text-default-700 text-sm">
                          {block.text}
                          {block.images && (
                            <div className="grid grid-cols-3 gap-4 mt-4">
                              {block.images.map((img, i) => (
                                <Link key={i} to="#">
                                  <img src={img} alt="chat-img" className="rounded-md" />
                                </Link>
                              ))}
                            </div>
                          )}
                        </div>
                      ))}
                  </div>

                  <Link
                    to="#"
                    className="flex items-center justify-center text-sm font-semibold rounded-full size-9 bg-default-200"
                  >
                    <img
                      src={msg.avatar}
                      alt="avatar"
                      className="object-cover rounded-full h-9"
                      width={36}
                      height={36}
                    />
                  </Link>
                </div>
              )
            )}
          </div>
        </div>
      </SimplebarClient>

      <div className="card-body">
        <div className="flex gap-2 items-center">
          <input
            type="text"
            className="form-input w-full"
            placeholder="Type your message here..."
          />
          <div className="flex items-center gap-2">
            <button className="btn size-9 bg-danger/10 text-danger hover:bg-danger hover:text-white">
              <LuMic className="size-4" />
            </button>
            <button className="btn size-9 bg-primary/10 text-primary hover:bg-primary hover:text-white">
              <LuImage className="size-4" />
            </button>
            <button className="btn bg-primary text-white flex items-center gap-1">
              <LuSend className="size-4" /> Send
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UserChats;
