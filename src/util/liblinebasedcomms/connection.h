// copyright 2010 t. schneider tes@mit.edu
//
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This software is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this software.  If not, see <http://www.gnu.org/licenses/>.

#ifndef ASIOLineBasedConnection20100715H
#define ASIOLineBasedConnection20100715H


namespace goby
{
    namespace util
    {

// template for type of client socket (asio::serial_port, asio::ip::tcp::socket)
        
        template<typename ASIOAsyncReadStream>
            class LineBasedConnection
        {

          protected:
            LineBasedConnection<ASIOAsyncReadStream>()
            {}
            
            virtual ASIOAsyncReadStream& socket () = 0;
            
            void read_start()
            {
                async_read_until(socket(), buffer_, LineBasedInterface::delimiter_,
                                 boost::bind(&LineBasedConnection::read_complete,
                                             this,
                                             boost::asio::placeholders::error));
            }
            
            void write_start()
            { // Start an asynchronous write and call write_complete when it completes or fails
                // don't write if it has a dest and the id doesn't match
                if(!(out_.front().has_dest() && out_.front().dest() != remote_endpoint()))
                {
                    boost::asio::async_write(socket(),
                                             boost::asio::buffer(out_.front().data()),
                                             boost::bind(&LineBasedConnection::write_complete,
                                                         this,
                                                         boost::asio::placeholders::error));
                }
                else
                {
                    // discard message not for our remote endpoint
                    out_.pop_front();
                }
            }
            
            void read_complete(const boost::system::error_code& error)
            {     
                if(error) return socket_close(error);

                std::istream is(&buffer_);

                std::string& line = *in_datagram_.mutable_data();

                if(!remote_endpoint().empty())
                    in_datagram_.set_src(remote_endpoint());
                if(!local_endpoint().empty())
                    in_datagram_.set_dest(local_endpoint());

                char last = LineBasedInterface::delimiter_.at(LineBasedInterface::delimiter_.length()-1);
                while(!std::getline(is, line, last).eof())
                {
                    line = extra_ + line + last;
                    // grab a lock on the in_ deque because the user can modify    
                    boost::mutex::scoped_lock lock(LineBasedInterface::in_mutex_);
                    
                    LineBasedInterface::in_.push_back(in_datagram_);
                    
                    extra_.clear();
                }
                
                // store any remainder for the next round
                if(!line.empty()) extra_ = line;
                
                read_start(); // start waiting for another asynchronous read again
            }    

            void write_complete(const boost::system::error_code& error)
            { // the asynchronous read operation has now completed or failed and returned an error
                if(error) return socket_close(error);
                
                out_.pop_front(); // remove the completed data
                if (!out_.empty()) // if there is anthing left to be written
                    write_start(); // then start sending the next item in the buffer
            }

            virtual void socket_close(const boost::system::error_code& error) = 0;
            
            virtual std::string local_endpoint() = 0;
            virtual std::string remote_endpoint() = 0;
            
            std::deque<protobuf::Datagram>& out() { return out_; }
            
            
          private:
            boost::asio::streambuf buffer_; 
            std::string extra_;
            protobuf::Datagram in_datagram_;
            std::deque<protobuf::Datagram> out_; // buffered write data
                
            
        };
    }
}

#endif