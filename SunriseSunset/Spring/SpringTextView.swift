// The MIT License (MIT)
//
// Copyright (c) 2015 Meng To (meng@designcode.io)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

open class SpringTextView: UITextView, Springable {
    @IBInspectable open var autostart: Bool = false
    @IBInspectable open var autohide: Bool = false
    @IBInspectable open var animation: String = ""
    @IBInspectable open var force: CGFloat = 1
    @IBInspectable open var delay: CGFloat = 0
    @IBInspectable open var duration: CGFloat = 0.7
    @IBInspectable open var damping: CGFloat = 0.7
    @IBInspectable open var velocity: CGFloat = 0.7
    @IBInspectable open var repeatCount: Float = 1
    @IBInspectable open var x: CGFloat = 0
    @IBInspectable open var y: CGFloat = 0
    @IBInspectable open var scaleX: CGFloat = 1
    @IBInspectable open var scaleY: CGFloat = 1
    @IBInspectable open var rotate: CGFloat = 0
    @IBInspectable open var curve: String = ""
    open var opacity: CGFloat = 1
    open var animateFrom: Bool = false

    lazy fileprivate var spring : Spring = Spring(self)

    override open func awakeFromNib() {
        super.awakeFromNib()
        self.spring.customAwakeFromNib()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        spring.customLayoutSubviews()
    }

    open func animate() {
        self.spring.animate()
    }

    open func animateNext(_ completion: () -> ()) {
        self.spring.animateNext(completion)
    }

    open func animateTo() {
        self.spring.animateTo()
    }

    open func animateToNext(_ completion: () -> ()) {
        self.spring.animateToNext(completion)
    }

}
